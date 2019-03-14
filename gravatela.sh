#!/bin/sh
if [ `uname` = "Darwin" ]; then
	GRAB="avfoundation"
else
	GRAB="x11grab"
fi

TMP=/tmp
OUT=$HOME/Desktop
if [ $# = 0 ] && [ -f $TMP/$USER.gravatela.pid ]; then
	echo "Finalizando a gravação"
	kill -TERM `cat $TMP/$USER.gravatela.pid`;
	rm -rf cat $TMP/$USER.gravatela.pid
elif [ $# = 0 ]; then
	echo "Iniciando a gravação"
	# Aqui descobre a resolução
	if [ $GRAB = "x11grab" ]; then
		RESOLUCAO=`xdpyinfo | grep 'dimensions:'| awk '{print $2}' | cut -f 1 -d 'x'`
		if [ $RESOLUCAO = "3840" ]; then
			OFFSET=1920
		elif [ $RESOLUCAO = "3286" ]; then
			OFFSET=1366
		elif [ $RESOLUCAO = "3360" ]; then
			OFFSET=1440
		elif [ $RESOLUCAO = "1920" ] || [ $RESOLUCAO = "1366" ] || [ $RESOLUCAO = "1440" ]; then
			OFFSET=0
		else
			echo "Resolucao desconhecida"
			exit 1
		fi
	else #avfoundation
		DEVICE=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "Capture screen 1" | awk '{print $6 $7 $8 $9}'`
		if [ "$DEVICE" != "[2]Capturescreen1" ]; then
			SCREENDEVICEINDEX=1
		else
			SCREENDEVICEINDEX=0
		fi
	fi
	unlink $OUT/$USER.VideoAudio.mkv
	touch $TMP/$USER.VideoAudio.mkv
	ln -s $TMP/$USER.VideoAudio.mkv $OUT/$USER.VideoAudio.mkv
	if [ -f $TMP/$USER.gravacamera.pid  ]; then
		if [ $GRAB = "x11grab" ]; then
			if [ $OFFSET != 0 ]; then
                        	ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -f x11grab -i :0.0+$OFFSET,0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &
                	else
                        	ffmpeg -y -loglevel error -video_size `xdpyinfo | grep 'dimensions:'| awk '{print $2}'` -framerate 30 -vsync 1 -f x11grab -i :0.0+$OFFSET,0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &
                	fi
		else
			ffmpeg -y -loglevel error -f avfoundation -framerate 30 -vsync 1 -pix_fmt nv12 -i "$SCREENDEVICEINDEX:" -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &
		fi
	else
		if [ $GRAB = "x11grab" ]; then
			if [ $OFFSET != 0 ]; then
				ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -f x11grab -i :0.0+$OFFSET,0 -f alsa -ar 44100 -ac 2 -async 44100  -i hw:0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &
			else
				ffmpeg -y -loglevel error -video_size `xdpyinfo | grep 'dimensions:'| awk '{print $2}'` -framerate 30 -vsync 1 -f x11grab -i :0.0+$OFFSET,0 -f alsa -ar 44100 -ac 2 -async 44100  -i hw:0 -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &
			fi
		else
			# Aqui Grava com a tela e audio
                        ffmpeg -y -loglevel error -f avfoundation -framerate 30 -vsync 1 -pix_fmt nv12  -i "$SCREENDEVICEINDEX:0" -async 44100  -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &	
		fi
	fi
	echo $! > $TMP/$USER.gravatela.pid
elif [ $# = 1 ] && [ -f $TMP/$USER.gravacamera.pid ]; then
        kill -TERM `cat $TMP/$USER.gravacamera.pid`;
        rm -rf cat $TMP/$USER.gravacamera.pid
elif [ $# = 1 ]; then
	#Vamos gravar da camera
	# So tem o código compatível com Linux e FreeBSD. Falta o do OS X
	unlink $OUT/$USER.CameraAudio.mkv
        touch $TMP/$USER.CameraAudio.mkv
        ln -s $TMP/$USER.CameraAudio.mkv $OUT/$USER.CameraAudio.mkv
	if [ -f $TMP/$USER.gravatela.pid  ]; then
		ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -vcodec h264 -f v4l2 -i $1 -c:v copy /home/ota/Desktop/$USER.CameraAudio.mkv &
	else
		ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -vcodec h264 -f v4l2 -i $1 -f alsa -ar 44100 -ac 2 -async 44100  -i hw:0 -c:v copy /home/ota/Desktop/$USER.CameraAudio.mkv &
	fi
	echo $! > $TMP/$USER.gravacamera.pid
fi
