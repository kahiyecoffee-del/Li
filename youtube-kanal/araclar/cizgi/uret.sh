#!/bin/bash
# Tam bölüm üretimi: duygulu ses -> render -> HEVC sıkıştırma + Shorts.  Yeniden çalıştırılabilir (önbellekli).
# Kullanım: araclar/cizgi/uret.sh budgets b03   |   araclar/cizgi/uret.sh comedown c02
SER=$1; SLUG=$2
SP=${SP:-/tmp/claude-0/-home-user-Li/e70ecee3-7ccd-56ad-a124-e08414ca6ca8/scratchpad}
cd "$(dirname "$0")/../.."
case $SER in
  budgets) CTA="dale|happy|Full episode is on the channel. Subscribe, or Homi fires you." ;;
  comedown) CTA="tuna|happy|Full episode is on the channel. Subscribe. It is cheaper than therapy." ;;
esac
OUT=cikti/$SER/$SLUG; mkdir -p $OUT
set -e
HF_HOME=$SP/hf HF_HUB_OFFLINE=1 $SP/sdvenv/bin/python araclar/cizgi/ses_cb.py senaryolar/$SER/$SLUG.txt --extra "$CTA"
[ -f $OUT/$SLUG.mp4 ] && [ $OUT/$SLUG.mp4 -nt senaryolar/$SER/$SLUG.txt ] || TTS_ENGINE=cb KOKORO_DIR=/home/user/models python3 araclar/cizgi/motor.py senaryolar/$SER/$SLUG.txt
[ -f $OUT/${SLUG}_yt.mp4 ] || araclar/cizgi/sikistir.sh $OUT/$SLUG.mp4 $OUT/${SLUG}_yt.mp4 &
TTS_ENGINE=cb KOKORO_DIR=/home/user/models python3 araclar/cizgi/shorts.py senaryolar/$SER/$SLUG.txt senaryolar/$SER/${SLUG}_shorts.json
wait
rm -f $OUT/$SLUG.wav
echo URETDONE
