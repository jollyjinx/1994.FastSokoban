#!/bin/sh

if [ "`whoami`x" = "jollyx" ];
then
	mom=`grep VERSION version.h | awk 'BEGIN{ FS = "\"" }{print $2}'|awk 'BEGIN { FS = "." }{ if( $3>8 ){ print $1"."$2+1 ".0" } else { print $1"."$2"."$3+1 } }'`
	echo '#define VERSION "'$mom'"' >version.h
	date|awk '{print "#define DATE \""$2,$3,$7"\""}' >>version.h
else
	touch version.h
fi
