"""CPU LoRA fine-tuning of Qwen2.5-1.5B-Instruct into Lio, resumable.

Runs inside GitHub Actions (no GPU): trains for --time-budget seconds,
saves the adapter + optimizer + position to --state, and the next job
continues from there. --merge writes the merged HF checkpoint.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import random
import time

import torch
from peft import LoraConfig, PeftModel, get_peft_model
from transformers import AutoModelForCausalLM, AutoTokenizer

BASE = "Qwen/Qwen2.5-1.5B-Instruct"


def encode(tok, msgs, max_len):
    """Token ids + labels; only assistant tokens are learned."""
    ids, labels = [], []
    for i in range(1, len(msgs) + 1):
        if msgs[i - 1]["role"] != "assistant":
            continue
        prompt = tok.apply_chat_template(msgs[: i - 1], tokenize=False, add_generation_prompt=True)
        full = tok.apply_chat_template(msgs[:i], tokenize=False)
        p_ids = tok(prompt, add_special_tokens=False)["input_ids"]
        f_ids = tok(full, add_special_tokens=False)["input_ids"]
        new = f_ids[len(ids):]
        n_prompt_new = max(0, len(p_ids) - len(ids))
        ids = f_ids
        labels += [-100] * n_prompt_new + new[n_prompt_new:]
    return ids[:max_len], labels[:max_len]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--state", required=True, help="dir with adapter/optimizer/progress (created or resumed)")
    ap.add_argument("--time-budget", type=int, default=5 * 3600)
    ap.add_argument("--epochs", type=float, default=1.0)
    ap.add_argument("--max-len", type=int, default=448)
    ap.add_argument("--accum", type=int, default=8)
    ap.add_argument("--lr", type=float, default=2e-4)
    ap.add_argument("--merge", help="write merged model here and exit")
    args = ap.parse_args()
    torch.manual_seed(0)
    torch.set_num_threads(os.cpu_count() or 4)

    tok = AutoTokenizer.from_pretrained(BASE)
    if args.merge:
        base = AutoModelForCausalLM.from_pretrained(BASE, torch_dtype=torch.float32)
        model = PeftModel.from_pretrained(base, os.path.join(args.state, "adapter")).merge_and_unload()
        model.to(torch.bfloat16).save_pretrained(args.merge, safe_serialization=True)
        tok.save_pretrained(args.merge)
        print("merged ->", args.merge)
        return

    rows = [json.loads(l) for l in open(args.data, encoding="utf-8")]
    random.Random(0).shuffle(rows)
    total = int(len(rows) * args.epochs)
    os.makedirs(args.state, exist_ok=True)
    prog_path = os.path.join(args.state, "progress.json")
    prog = json.load(open(prog_path)) if os.path.exists(prog_path) else {"pos": 0, "updates": 0, "loss": []}
    if prog["pos"] >= total:
        print("training already complete:", prog)
        return

    dtype = torch.bfloat16
    base = AutoModelForCausalLM.from_pretrained(BASE, torch_dtype=dtype)
    base.gradient_checkpointing_enable()
    base.enable_input_require_grads()
    adapter_dir = os.path.join(args.state, "adapter")
    if os.path.exists(os.path.join(adapter_dir, "adapter_config.json")):
        model = PeftModel.from_pretrained(base, adapter_dir, is_trainable=True)
    else:
        cfg = LoraConfig(r=16, lora_alpha=32, lora_dropout=0.05, task_type="CAUSAL_LM",
                         target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"])
        model = get_peft_model(base, cfg)
    for p in model.parameters():
        if p.requires_grad:
            p.data = p.data.float()
    model.print_trainable_parameters()
    params = [p for p in model.parameters() if p.requires_grad]
    opt = torch.optim.AdamW(params, lr=args.lr, weight_decay=0.0)
    opt_path = os.path.join(args.state, "optim.pt")
    if os.path.exists(opt_path):
        opt.load_state_dict(torch.load(opt_path))
    total_updates = math.ceil(total / args.accum)

    def lr_at(u):
        warm = 20
        if u < warm:
            return args.lr * (u + 1) / warm
        return args.lr * 0.5 * (1 + math.cos(math.pi * min(1.0, (u - warm) / max(1, total_updates - warm))))

    model.train()
    start = time.time()
    acc_loss, acc_n = 0.0, 0
    while prog["pos"] < total and time.time() - start < args.time_budget:
        ex = rows[prog["pos"] % len(rows)]
        ids, labels = encode(tok, ex["messages"], args.max_len)
        x = torch.tensor([ids])
        y = torch.tensor([labels])
        with torch.autocast("cpu", dtype=dtype):
            out = model(input_ids=x, labels=y)
        (out.loss / args.accum).backward()
        acc_loss += out.loss.item()
        acc_n += 1
        prog["pos"] += 1
        if acc_n == args.accum or prog["pos"] >= total:
            for g in opt.param_groups:
                g["lr"] = lr_at(prog["updates"])
            torch.nn.utils.clip_grad_norm_(params, 1.0)
            opt.step()
            opt.zero_grad(set_to_none=True)
            prog["updates"] += 1
            prog["loss"].append(round(acc_loss / acc_n, 4))
            el = time.time() - start
            print(f"update {prog['updates']}/{total_updates} pos {prog['pos']}/{total} loss {acc_loss / acc_n:.4f} "
                  f"({el / prog['pos'] if prog['pos'] else 0:.1f}s/ex this job)", flush=True)
            acc_loss, acc_n = 0.0, 0
    # A partial accumulation at the time limit is dropped (its gradients
    # are discarded); position already advanced, so nothing repeats.
    opt.zero_grad(set_to_none=True)
    model.save_pretrained(adapter_dir)
    torch.save(opt.state_dict(), opt_path)
    json.dump(prog, open(prog_path, "w"))
    print("saved state:", {k: prog[k] for k in ("pos", "updates")}, "of", total)


if __name__ == "__main__":
    main()
