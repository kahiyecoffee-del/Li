#!/bin/bash
# Temiz oturum kurulumu (idempotent). THE BUDGETS / THE COMEDOWN üretimi için gereken her şey.
# Kullanım: bash araclar/cizgi/kurulum.sh     (~10-15 dk ilk seferde)
set -e
cd "$(dirname "$0")/../.."
pip install -q pycairo kokoro-onnx soundfile numpy 2>&1 | grep -viE "already|warning: running pip" || true
mkdir -p /home/user/models
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  [ -s /home/user/models/$f ] || curl -sSL -o /home/user/models/$f https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/$f
done
CB=${CBVENV:-/home/user/cbvenv}
if ! $CB/bin/python -c "import chatterbox, cairo, perth; assert perth.PerthImplicitWatermarker" 2>/dev/null; then
  python3 -m venv $CB
  $CB/bin/pip install -q torch torchaudio --index-url https://download.pytorch.org/whl/cpu
  $CB/bin/pip install -q --no-deps chatterbox-tts==0.1.7
  $CB/bin/pip install -q librosa s3tokenizer conformer==0.3.2 resemble-perth pyloudnorm omegaconf transformers==5.22.2 \
      diffusers safetensors "setuptools<81" pycairo numpy soundfile 2>&1 | grep -v "requires" || true
fi
export HF_HOME=${HF_HOME_CB:-/home/user/.cache/hf} HF_HUB_DISABLE_XET=1
$CB/bin/python -c "from chatterbox.tts import ChatterboxTTS; ChatterboxTTS.from_pretrained(device='cpu')" 2>&1 | grep -iE "error|traceback" || true
[ -f cikti/sesler/ref_dale.wav ] || KOKORO_DIR=/home/user/models python3 araclar/cizgi/ses_ref.py
echo KURULUM_OK
