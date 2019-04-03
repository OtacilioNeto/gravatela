#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Você precisa informar o identificador da live"
	exit 1
fi
IDENTIFICADOR=$1

if [ `uname` = "Darwin" ]; then
    GRAB="avfoundation"
else
    GRAB="x11grab"
fi

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

    ffmpeg -f alsa -ac 1 -i default -f x11grab -framerate 24 -video_size 1920x1080 -i :0.0+$OFFSET,0 -preset medium -r 24 -g 48 -acodec libmp3lame -ar 44100 -threads 4 -qscale 3 -qmax 10 -b:a 4092k  -f flv -s 1920x1080  rtmp://a.rtmp.youtube.com/live2/$IDENTIFICADOR 2>&1 > /dev/null
else
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
    ffmpeg -y -loglevel error -ac 1 -f avfoundation -framerate 24 -pix_fmt nv12 -i "$SCREENDEVICEINDEX:0" -vcodec libx264 -preset ultrafast -minrate 1500k -maxrate 4500k -r 24 -g 48 -acodec libmp3lame -ar 44100 -threads 4 -qscale 3 -qmax 10 -b:a 4096k  -f flv rtmp://a.rtmp.youtube.com/live2/$IDENTIFICADOR 2>&1 >/dev/null
fi
