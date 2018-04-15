#!/bin/bash

cat <<EOF | awesome-client
nvlled.showTimer()
EOF

dir=~/screencast
date=`date +%H%M-%d-%b-%y | tr [:upper:] [:lower:]`
filename=$dir/slack-$date.mkv

mkdir -p $dir

ffmpeg \
    -loglevel error \
    -y `#overwrite without asking` \
    -t 1:00:00  `#length of video` \
    -an `#disable audio` \
    -video_size 1280x1024 \
    -framerate 20 \
    -f x11grab \
    -i :0 \
    -crf 24 `#smaller output size I think` \
    -b:v 512 \
    $filename


cat <<EOF | awesome-client
nvlled.hideTimer()
nvlled.notify{
    text = "screencast done",
    font = "sans 30",
    bg = "#eeeeee",
    fg = "#ee5555",
}
EOF
