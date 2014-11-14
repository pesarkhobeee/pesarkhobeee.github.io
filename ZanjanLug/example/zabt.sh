ffmpeg -f alsa -itsoffset 00:00:02.000 -ac 2 -i hw:0,0 -f x11grab -s $(xwininfo -root | grep 'geometry' | awk '{print $2;}') -r 10 -i :0.0 -sameq -f avi -s wvga -y intro.avi

