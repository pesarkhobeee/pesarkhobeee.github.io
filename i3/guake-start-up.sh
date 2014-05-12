#!/bin/bash

# index of last opened tab
lastTabIndex=-1

function runGuake {
	# run guake in another proccess
	nohup guake > /dev/null & 
	# wait for guake
	sleep 5
	# rename default tab if we have a name for it
	if [ "$1" ]; then
		guake -r $1
	fi
	# increase index of lastTab
	lastTabIndex=`echo $lastTabIndex+1 | bc`
}

function newGuakeTab {
	# create new tab
	guake -n $1
	# rename tab
	guake -r $1
	# increase index of lastTab
	lastTabIndex=`echo $lastTabIndex+1 | bc`
	# switch to last tab (FIXME: do we need it?)
	guake -s $lastTabIndex
	# execute command in tab if anything passed
	if [ "$2" ]; then
		guake -e "$2"
	fi
}

sleep 20

runGuake "local"
newGuakeTab "alternate"
newGuakeTab "www" "cd /srv/www/html"
newGuakeTab "sudo" "sudo -s"

exit

