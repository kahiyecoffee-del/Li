#!/usr/bin/env python3
"""DEAD QUOTA yerel görsel üretimi (SDXL, CPU).

Kullanım:
    python araclar/gorsel_uret.py --prompt "..." --out cikti/dizi/ai/kare.png [--w 1344 --h 768 --steps 28 --seed 7]
    python araclar/gorsel_uret.py --batch liste.json      # [{"prompt":..., "out":..., "seed":...}, ...]

Sanat yönetimi: senaryolar/dizi-dead-quota-sanat-yonetimi.md içindeki [STYLE] bloğu otomatik eklenir,
negatif blok da otomatik verilir. Böylece her kare aynı stil kurallarıyla üretilir.
"""
import argparse
import gc
import json
import os
import time

import torch
from diffusers import StableDiffusionXLPipeline, EulerAncestralDiscreteScheduler

MODEL = os.environ.get("SDXL_MODEL", "stabilityai/stable-diffusion-xl-base-1.0")

# Not: SDXL metin kodlayıcıları ~77 token görür. Önce özne/karakter, sonra kısa stil bloğu gelir.
STYLE = ("full color, adult animated TV series still, 2D cel animation, bold clean dark outlines, hard cel shading, "
         "flat saturated colors, painterly background, cinematic lighting")
NEG = ("black and white, monochrome, grayscale, anime, manga, chibi, big anime eyes, pixar, disney, 3d render, cgi, soft gradient shading, airbrush, glossy skin, "
       "plastic skin, photorealistic, photograph, watercolor, pastel, sketchy lines, children's cartoon, blurry, lowres, "
       "deformed, extra fingers, extra limbs, bad anatomy, text, watermark, logo, signature")

torch.set_num_threads(os.cpu_count() or 4)
_pipe = None


def pipe():
    global _pipe
    if _pipe is None:
        p = StableDiffusionXLPipeline.from_pretrained(MODEL, torch_dtype=torch.bfloat16, use_safetensors=True, variant="fp16")
        p.scheduler = EulerAncestralDiscreteScheduler.from_config(p.scheduler.config)
        p.enable_attention_slicing()
        p.vae.enable_tiling()
        p.set_progress_bar_config(disable=False)
        ipa = os.environ.get("IPADAPTER_DIR")
        if ipa:
            p.load_ip_adapter(ipa, subfolder="sdxl_models", weight_name="ip-adapter-plus_sdxl_vit-h.safetensors",
                              image_encoder_folder="models/image_encoder", torch_dtype=torch.bfloat16)
            p.image_encoder.to(torch.bfloat16)
        _pipe = p
    return _pipe


def gen(prompt, out, w=1344, h=768, steps=28, seed=7, cfg=6.5, style=True, ref=None, ref_scale=0.5):
    p = pipe()
    full = f"{prompt}, {STYLE}" if style else prompt
    g = torch.Generator("cpu").manual_seed(seed)
    t = time.time()
    extra = {}
    if getattr(p, "image_encoder", None) is not None:
        from PIL import Image
        if ref:
            p.set_ip_adapter_scale(ref_scale)
            extra["ip_adapter_image"] = Image.open(ref).convert("RGB")
        else:
            p.set_ip_adapter_scale(0.0)
            extra["ip_adapter_image"] = Image.new("RGB", (224, 224), (128, 128, 128))
    with torch.inference_mode():
        img = p(prompt=full, negative_prompt=NEG, width=w, height=h, num_inference_steps=steps,
                guidance_scale=cfg, generator=g, **extra).images[0]
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    img.save(out)
    print(f"✔ {out}  ({time.time() - t:.0f} sn)", flush=True)
    gc.collect()
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt")
    ap.add_argument("--out")
    ap.add_argument("--batch")
    ap.add_argument("--w", type=int, default=1344)
    ap.add_argument("--h", type=int, default=768)
    ap.add_argument("--steps", type=int, default=28)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--cfg", type=float, default=6.5)
    a = ap.parse_args()
    if a.batch:
        for it in json.load(open(a.batch, encoding="utf-8")):
            if it.get("skip_if_exists") and os.path.exists(it["out"]):
                continue
            gen(it["prompt"], it["out"], it.get("w", a.w), it.get("h", a.h), it.get("steps", a.steps), it.get("seed", a.seed), it.get("cfg", a.cfg),
                ref=it.get("ref"), ref_scale=it.get("ref_scale", 0.5))
    else:
        gen(a.prompt, a.out, a.w, a.h, a.steps, a.seed, a.cfg)
