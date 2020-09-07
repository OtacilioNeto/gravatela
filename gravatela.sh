#!/bin/sh
if [ `uname` = "Darwin" ]; then
	GRAB="avfoundation"
else
	GRAB="x11grab"
	if [ -e /dev/dri/renderD128 ]; then
		VAAPI_DEVICE="-vaapi_device /dev/dri/renderD128"
		ENCODER="-vf format=nv12,hwupload -c:v h264_vaapi -qp 18"
	else
		VAAPI_DEVICE=""
		ENCODER="-c:v libx264 -preset ultrafast"
	fi
fi

TMP=/tmp
OUT=$HOME/Desktop
if [ $# = 0 ] && [ -f $TMP/$USER.gravatela.pid ]; then
	PID=`cat $TMP/$USER.gravatela.pid`
	echo "Finalizando a gravação da tela (pid=$PID)"
	kill -TERM $PID;
	rm -rf cat $TMP/$USER.gravatela.pid
elif [ $# = 0 ]; then
	if [ "$VAAPI_DEVICE" = "" ]; then
		echo "Codificando via libx264"
	else
		echo "Codificando via vaapi"
	fi
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
		DEVICE0=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "Capture screen 0" | awk '{print $7 $8 $9}'`
		DEVICE1=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "Capture screen 1" | awk '{print $7 $8 $9}'`
		if [ "$DEVICE1" == "Capturescreen1" ]; then
			SCREENDEVICEINDEX=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "Capture screen 1" | awk '{print $6}' | awk -F "[" '{print $2}' | awk -F "]" '{print $1}'`
		elif [ "$DEVICE0" == "Capturescreen0" ]; then
			SCREENDEVICEINDEX=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "Capture screen 0" | awk '{print $6}' | awk -F "[" '{print $2}' | awk -F "]" '{print $1}'`
		else
			echo "Erro ao detectar o dispositivo"
			exit 1
		fi
		echo "Usando dispositivo $SCREENDEVICEINDEX"
	fi
	if [ -f $OUT/$USER.VideoAudio.mkv ]; then
		unlink $OUT/$USER.VideoAudio.mkv
	fi
	touch $TMP/$USER.VideoAudio.mkv
	ln -s $TMP/$USER.VideoAudio.mkv $OUT/$USER.VideoAudio.mkv
	if [ -f $TMP/$USER.gravacamera.pid  ]; then
		if [ $GRAB = "x11grab" ]; then
			if [ $OFFSET != 0 ]; then
            	# Aqui também precisa calcular as dimensões da tela a ser gravada
                ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 $VAAPI_DEVICE -f x11grab -i $DISPLAY+$OFFSET,0 $ENCODER -crf 0 $TMP/$USER.VideoAudio.mkv &
            else
                ffmpeg -y -loglevel error -video_size `xdpyinfo | grep 'dimensions:'| awk '{print $2}'` -framerate 30 $VAAPI_DEVICE -f x11grab -i $DISPLAY+$OFFSET,0 $ENCODER -crf 0 $TMP/$USER.VideoAudio.mkv &
            fi
		else
			ffmpeg -y -loglevel error -f avfoundation -framerate 30 -pix_fmt nv12 -i "$SCREENDEVICEINDEX:" -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &
		fi
	else
		if [ $GRAB = "x11grab" ]; then
			if [ $OFFSET != 0 ]; then
				ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 $VAAPI_DEVICE -f x11grab -i $DISPLAY+$OFFSET,0 -f alsa -ar 44100 -ac 2 -async 1  -i hw:0 $ENCODER -crf 0 $TMP/$USER.VideoAudio.mkv &
			else
				ffmpeg -y -loglevel error -video_size `xdpyinfo | grep 'dimensions:'| awk '{print $2}'` -framerate 30 $VAAPI_DEVICE -f x11grab -i $DISPLAY+$OFFSET,0 -f alsa -ar 44100 -ac 2 -async 1  -i hw:0 $ENCODER $TMP/$USER.VideoAudio.mkv &
			fi
		else
			# Aqui Grava com a tela e audio
			# Usar -vsync 1 faz com que o ffmpeg trave quando grava na saída HDMI
            ffmpeg -y -loglevel error -f avfoundation -framerate 30 -pix_fmt nv12  -i "$SCREENDEVICEINDEX:0" -async 88200  -c:v libx264 -crf 0 -preset ultrafast $TMP/$USER.VideoAudio.mkv &	
		fi
	fi
	echo $! > $TMP/$USER.gravatela.pid
elif [ $# = 1 ] && [ -f $TMP/$USER.gravacamera.pid ]; then
	PID=`cat $TMP/$USER.gravacamera.pid`
	echo "Finalizando a gravação da câmera (pid=$PID)"
	kill -TERM $PID;
	rm -rf cat $TMP/$USER.gravacamera.pid
elif [ $# = 1 ]; then
	#Vamos gravar da camera
	# So tem o código compatível com Linux e FreeBSD. Falta o do OSX
	if [ -f $OUT/$USER.CameraAudio.mkv ]; then
		unlink $OUT/$USER.CameraAudio.mkv
	fi
    touch $TMP/$USER.CameraAudio.mkv
    ln -s $TMP/$USER.CameraAudio.mkv $OUT/$USER.CameraAudio.mkv
	if [ $GRAB = "x11grab" ]; then
		if [ -f $TMP/$USER.gravatela.pid  ]; then	
			# Se já está gravando a tela, grave a câmera sem áudio porque o processo que está gravando a tela já está lendo do microfone
			ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -vcodec h264 -f v4l2 -i $1 -c:v copy /home/ota/Desktop/$USER.CameraAudio.mkv &
		else
			# Não está gravando a tela, então leia do microfone
			ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -vcodec h264 -f v4l2 -i $1 -f alsa -ar 44100 -ac 2 -async 44100 -i hw:0 -c:v copy /home/ota/Desktop/$USER.CameraAudio.mkv &
		fi
	else
		# Aqui eh para o caso de estar usando o OS X
		DEVICE=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "HD Pro Webcam C920" | awk '{print $7 $8 $9}' | head -n 1`
		if [ $DEVICE = "HDProWebcam" ]; then
			SCREENDEVICEINDEX=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "HD Pro Webcam C920" | awk '{print $6}' | awk -F "[" '{print $2}' | awk -F "]" '{print $1}' | head -n 1`
			echo "Gravando do dispositivo $SCREENDEVICEINDEX"
			if [ -f $TMP/$USER.gravatela.pid  ]; then
				echo "Opção não implementada"
				exit 1
            	# Se já está gravando a tela, grave a câmera sem áudio porque o processo que está gravando a tela já está lendo do microfone
                ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -vcodec h264 -f v4l2 -i $1 -c:v copy /home/ota/Desktop/$USER.CameraAudio.mkv &
            else
				echo "Não está funcionando a gravação direto da câmera do MAC"
				exit 1
                # Não está gravando a tela, então leia da camera
                ffmpeg -y -loglevel error -video_size 1920x1080 -framerate 30 -vsync 1 -vcodec h264 -f avfoundation -pix_fmt nv12 -i "$SCREENDEVICEINDEX:1" -async 88200  -c:v copy /Users/otacilio/Desktop/$USER.CameraAudio.mkv &
            fi
		else
			echo "Precisa adicionar o código para gravar da câmera do MAC"
		fi		
	fi
	echo $! > $TMP/$USER.gravacamera.pid
fi
