#!/bin/bash
# Tam bölüm üretimi: duygulu ses -> render -> HEVC sıkıştırma + Shorts -> disk temizliği. Yeniden çalıştırılabilir.
# Kullanım: araclar/cizgi/uret.sh budgets b03   |   araclar/cizgi/uret.sh comedown c02   (önce: bash araclar/cizgi/kurulum.sh)
SER=$1; SLUG=$2
CB=${CBVENV:-/home/user/cbvenv}
export HF_HOME=${HF_HOME_CB:-/home/user/.cache/hf}
cd "$(dirname "$0")/../.."
case $SER in
  budgets) CTA="dale|happy|Full episode is on the channel. Subscribe, or Homi fires you." ;;
  comedown) CTA="tuna|happy|Full episode is on the channel. Subscribe. It is cheaper than therapy." ;;
esac
OUT=cikti/$SER/$SLUG; mkdir -p $OUT
set -e
HF_HUB_OFFLINE=1 $CB/bin/python araclar/cizgi/ses_cb.py senaryolar/$SER/$SLUG.txt --extra "$CTA"
if [ ! -f $OUT/${SLUG}_yt.mp4 ]; then
  [ -f $OUT/$SLUG.mp4 ] && [ $OUT/$SLUG.mp4 -nt senaryolar/$SER/$SLUG.txt ] || TTS_ENGINE=cb KOKORO_DIR=/home/user/models python3 araclar/cizgi/motor.py senaryolar/$SER/$SLUG.txt
  araclar/cizgi/sikistir.sh $OUT/$SLUG.mp4 $OUT/${SLUG}_yt.mp4 &
fi
TTS_ENGINE=cb KOKORO_DIR=/home/user/models python3 araclar/cizgi/shorts.py senaryolar/$SER/$SLUG.txt senaryolar/$SER/${SLUG}_shorts.json
wait
# disk temizliği: ham video ve ara ses dosyaları (sıkıştırılmış sürüm ve Shorts kalır)
[ -s $OUT/${SLUG}_yt.mp4 ] && rm -f $OUT/$SLUG.mp4
rm -f $OUT/$SLUG.wav
echo URETDONE
