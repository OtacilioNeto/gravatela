#!/bin/sh
TMP=/tmp
OUT=/home/$USER/Desktop
if [ -f $TMP/$USER.gravatela.pid ]; then
	kill -TERM `cat $TMP/$USER.gravatela.pid`;
	rm -rf cat $TMP/$USER.gravatela.pid
else
	RESOLUCAO=`xdpyinfo | grep 'dimensions:'| awk '{print $2}' | cut -f 1 -d 'x'`
	if [ $RESOLUCAO = "3840" ]; then
		OFFSET=1920

	elif [ $RESOLUCAO = "1920" ]; then
		OFFSET=0
	else
		echo "Resolucao desconhecida"
		exit 1
	fi
	unlink $OUT/$USER.VideoAudio.avi
	touch $TMP/$USER.VideoAudio.avi
	ln -s $TMP/$USER.VideoAudio.avi $OUT/$USER.VideoAudio.avi
	ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -f x11grab -i :0.0+$OFFSET,0 -f alsa -ar 44100 -ac 2 -i hw:0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.avi &
	echo $! > $TMP/$USER.gravatela.pid
fi
