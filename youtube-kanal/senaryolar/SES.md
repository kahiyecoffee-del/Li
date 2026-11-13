# Duygulu seslendirme kurulumu (Chatterbox, CPU)

```bash
SP=<scratchpad>
python3 -m venv $SP/sdvenv   # (varsa atla)
$SP/sdvenv/bin/pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu
$SP/sdvenv/bin/pip install --no-deps chatterbox-tts==0.1.7
$SP/sdvenv/bin/pip install librosa s3tokenizer conformer==0.3.2 resemble-perth pyloudnorm omegaconf transformers diffusers safetensors "setuptools<81" pycairo numpy soundfile
KOKORO_DIR=/home/user/models python3 araclar/cizgi/ses_ref.py   # karakter referans sesleri (cikti/sesler)
```
- Model ilk çalıştırmada HF'den iner (HF_HOME=$SP/hf, HF_HUB_DISABLE_XET=1).
- Duygu eşlemesi `araclar/cizgi/ses_cb.py` içindeki EXAG/CFG tablolarında.
- Chatterbox çıktısında görünmez bir yapay zekâ filigranı (Perth) vardır; kapatılmaz.
