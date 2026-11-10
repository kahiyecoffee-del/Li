#!/usr/bin/env bash
# Gerekli Python paketlerini ve ücretsiz seslendirme modelini (Kokoro, ~350 MB) indirir.
set -e
cd "$(dirname "$0")"
pip install -r requirements.txt
mkdir -p modeller
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  [ -f "modeller/$f" ] || curl -L -o "modeller/$f" \
    "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/$f"
done
command -v ffmpeg >/dev/null || echo "UYARI: ffmpeg kurulu değil (apt install ffmpeg)"
echo "Kurulum tamam."
