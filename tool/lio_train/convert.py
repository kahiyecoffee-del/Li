"""Converts a (merged) Qwen2.5-1.5B checkpoint to a LiteRT-LM file for phones.

    python3 tool/lio_train/convert.py --ckpt merged/ --out out/ --name lio-qwen2.5-1.5b
"""
import argparse
import os

from litert_torch.generative.examples.qwen import qwen
from litert_torch.generative.layers import kv_cache as kv_utils
from litert_torch.generative.utilities import converter, export_config as export_config_lib
from transformers import AutoTokenizer


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--name", default="lio-qwen2.5-1.5b")
    ap.add_argument("--kv", type=int, default=1280)
    ap.add_argument("--quantize", default="dynamic_int8",
                    help="dynamic_int8 (~1.6 GB for 1.5B) or dynamic_int4_block32 (~half the size)")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    tok = AutoTokenizer.from_pretrained(args.ckpt)
    model = qwen.build_1_5b_model(args.ckpt, mask_cache_size=args.kv)
    # The LiteRT-LM runtime expects a [batch, heads, seq, dim] KV cache; the
    # default layout makes every message fail with "prefill work group size
    # exceeds available state entries".
    export_config = export_config_lib.ExportConfig(kvcache_layout=kv_utils.KV_LAYOUT_TRANSPOSED)
    converter.convert_to_litert(
        model,
        output_path=args.out,
        output_name_prefix=args.name,
        prefill_seq_len=[32, 128, 512],
        kv_cache_max_len=args.kv,
        quantize=args.quantize,
        export_config=export_config,
        output_format="litertlm",
        hf_tokenizer_model_path=os.path.join(args.ckpt, "tokenizer.json"),
        llm_model_type="qwen2p5",
        start_token_id=None,
        stop_tokens=["<|im_end|>", "<|endoftext|>"],
        user_prompt_prefix="<|im_start|>user\n",
        user_prompt_suffix="<|im_end|>\n",
        model_prompt_prefix="<|im_start|>assistant\n",
        model_prompt_suffix="<|im_end|>\n",
        jinja_prompt_template=tok.chat_template,
    )
    print(os.listdir(args.out))


if __name__ == "__main__":
    main()
