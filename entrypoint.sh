#!/bin/bash

export LC_ALL=ja_JP.UTF8

if [ $# -eq 0 ]; then
  cmd=`basename $0`
  echo "usage: $cmd connfig_name"
  echo "       $cmd channel duration(minuites) [prefix] [album artist]"
  exit 1
fi

if [ $# -eq 1 ]; then
  config=`jq .$1 /config.json`
  if [ $? -ne 0 ]; then
    exit 1
  fi
  if [ "null" = "$config" ]; then
    echo $1 not found.
    exit 1
  fi
  channel=`echo $config | jq -r .channel`
  duration=`echo $config | jq -r .duration`
  alubm=`echo $config | jq -r .album`
  artist=`echo $config | jq -r .artist`
  exec $0 $channel $duration $1 "$alubm" "$artist"
fi

date=`date '+%Y-%m-%d'`
playerurl=http://radiko.jp/apps/js/flash/myplayer-release.swf
playerfile=player.swf
keyfile=authkey.png

outdir=/data


if [ $# -ge 2 ]; then
  channel=$1
  DURATION=`expr $2 \* 60`
fi
PREFIX=${channel}
if [ $# -ge 3 ]; then
  PREFIX=$3
fi

if [ $# -ge 5 ]; then
  TITLE=$4
  ARTIST=$5
fi

#
# get player
#
if [ ! -f $playerfile ]; then
  wget -q -O $playerfile $playerurl

  if [ $? -ne 0 ]; then
    echo "failed get player"
    exit 1
  fi
fi

#
# get keydata (need swftool)
#
if [ ! -f $keyfile ]; then
  swfextract -b 12 $playerfile -o $keyfile

  if [ ! -f $keyfile ]; then
    echo "failed get keydata"
    exit 1
  fi
fi

#
# access auth1_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_ts" \
     --header="X-Radiko-App-Version: 4.0.0" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --post-data='\r\n' \
     --no-check-certificate \
     --save-headers \
     -O auth1_fms \
     https://radiko.jp/v2/api/auth1_fms

if [ $? -ne 0 ]; then
  echo "failed auth1 process"
  exit 1
fi

#
# get partial key
#
authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' auth1_fms`
offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' auth1_fms`
length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' auth1_fms`

partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

#
# access auth2_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_ts" \
     --header="X-Radiko-App-Version: 4.0.0" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --header="X-Radiko-AuthToken: ${authtoken}" \
     --header="X-Radiko-PartialKey: ${partialkey}" \
     --post-data='\r\n' \
     --no-check-certificate \
     -O auth2_fms \
     https://radiko.jp/v2/api/auth2_fms

if [ $? -ne 0 -o ! -f auth2_fms ]; then
  echo "failed auth2 process"
  exit 1
fi

#echo "authentication success"

areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' auth2_fms`
#echo "areaid: $areaid"

#
# get stream-url
#

if [ -f ${channel}.xml ]; then
  rm -f ${channel}.xml
fi

wget -q "http://radiko.jp/v2/station/stream/${channel}.xml"

stream_url=`echo "cat /url/item[1]/text()" | xmllint --shell ${channel}.xml | tail -2 | head -1`
url_parts=(`echo ${stream_url} | perl -pe 's!^(.*)://(.*?)/(.*)/(.*?)$/!$1://$2 $3 $4!'`)

#
# rtmpdump
#
#rtmpdump -q \
FLVFILE=${channel}_${date}
rtmpdump \
         -r ${url_parts[0]} \
         --app ${url_parts[1]} \
         --playpath ${url_parts[2]} \
         -W $playerurl \
         -C S:"" -C S:"" -C S:"" -C S:$authtoken \
         --live \
         --stop ${DURATION} \
         --flv "$FLVFILE"

OUTFILE=${PREFIX}_${date}.mp3
ffmpeg -loglevel quiet -y -i "$FLVFILE" -acodec libmp3lame -ab 128k "$OUTFILE"

if [ "$TITLE" != "" ]; then
  id3v2 -A "$TITLE" -a "$ARTIST" -t "$date ON AIR" "$OUTFILE"
fi

if [ -e "$OUTFILE" ]; then
  mv $OUTFILE $outdir
fi
