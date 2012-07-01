#/bin/bash

X=`setxkbmap -print -verbose 10 | grep layout | grep -o -e '[^ ]*$'`

if [ $X = "us" ] ; then
	setxkbmap ir
fi

if [ $X = "ir" ] ; then
	setxkbmap us
fi

