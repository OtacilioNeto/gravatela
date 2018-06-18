#!/bin/sh
TMP=/tmp
OUT=$HOME/Desktop
if [ $# = 0 ] && [ -f $TMP/$USER.gravatela.pid ]; then
	kill -TERM `cat $TMP/$USER.gravatela.pid`;
	rm -rf cat $TMP/$USER.gravatela.pid
elif [ $# = 0 ]; then
	RESOLUCAO=`xdpyinfo | grep 'dimensions:'| awk '{print $2}' | cut -f 1 -d 'x'`
	if [ $RESOLUCAO = "3840" ]; then
		OFFSET=1920
	elif [ $RESOLUCAO = "3286" ]; then
		OFFSET=1366
	elif [ $RESOLUCAO = "1920" ] || [ $RESOLUCAO = "1366" ]; then
		OFFSET=0
	else
		echo "Resolucao desconhecida"
		exit 1
	fi
	unlink $OUT/$USER.VideoAudio.avi
	touch $TMP/$USER.VideoAudio.avi
	ln -s $TMP/$USER.VideoAudio.avi $OUT/$USER.VideoAudio.avi
	if [ -f $TMP/$USER.gravacamera.pid  ]; then
		if [ $OFFSET != 0 ]; then
                        ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -f x11grab -i :0.0+$OFFSET,0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.avi &
                else
                        ffmpeg -y -loglevel error -video_size `xdpyinfo | grep 'dimensions:'| awk '{print $2}'` -framerate 30 -f x11grab -i :0.0+$OFFSET,0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.avi &
                fi
	else
		if [ $OFFSET != 0 ]; then
			ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -f x11grab -i :0.0+$OFFSET,0 -f alsa -ar 44100 -ac 2 -async 1  -i hw:0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.avi &
		else
			ffmpeg -y -loglevel error -video_size `xdpyinfo | grep 'dimensions:'| awk '{print $2}'` -framerate 30 -f x11grab -i :0.0+$OFFSET,0 -f alsa -ar 44100 -ac 2 -async 1  -i hw:0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.avi &
		fi
	fi
	echo $! > $TMP/$USER.gravatela.pid
elif [ $# = 1 ] && [ -f $TMP/$USER.gravacamera.pid ]; then
        kill -TERM `cat $TMP/$USER.gravacamera.pid`;
        rm -rf cat $TMP/$USER.gravacamera.pid
elif [ $# = 1 ]; then
	#Vamos gravar da camera
	unlink $OUT/$USER.CameraAudio.avi
        touch $TMP/$USER.CameraAudio.avi
        ln -s $TMP/$USER.CameraAudio.avi $OUT/$USER.CameraAudio.avi
	if [ -f $TMP/$USER.gravatela.pid  ]; then
		ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vcodec h264 -f v4l2 -i $1 -c:v copy /home/ota/Desktop/$USER.CameraAudio.avi &
	else
		ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vcodec h264 -f v4l2 -i $1 -f alsa -ar 44100 -ac 2 -async 1  -i hw:0 -c:v copy /home/ota/Desktop/$USER.CameraAudio.avi &
	fi
	echo $! > $TMP/$USER.gravacamera.pid
fi
