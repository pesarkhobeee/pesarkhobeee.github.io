#convert -resize WIDTHxHEIGHT source.jpg target.png
for k in *.JPG; do convert -resize 300 -quality 80 "$k" "pic/$k"; done

