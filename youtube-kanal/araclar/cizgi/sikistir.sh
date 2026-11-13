#!/bin/bash
# Kullanım: araclar/cizgi/sikistir.sh giris.mp4 cikis.mp4 [hedef_MB=92]
# GitHub 100 MB sınırı için HEVC 2 geçiş; YouTube HEVC kabul eder.
IN=$1; OUT=$2; MB=${3:-92}
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
VB=$(python3 -c "print(int(($MB*8*1024*1024/$D - 128000)/1000))")
T=$(mktemp -d)
ffmpeg -v error -y -i "$IN" -c:v libx265 -preset fast -b:v ${VB}k -x265-params pass=1:stats=$T/x265.log:log-level=error -an -f null /dev/null
ffmpeg -v error -y -i "$IN" -c:v libx265 -preset fast -b:v ${VB}k -x265-params pass=2:stats=$T/x265.log:log-level=error -tag:v hvc1 -c:a aac -b:a 128k -movflags +faststart "$OUT"
rm -rf "$T"
ls -la "$OUT"
