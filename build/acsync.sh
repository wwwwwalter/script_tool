#!/bin/bash

PRO_PATH=~/work/private/propath
OPEN_FILES=`ls $PRO_PATH`
CODE_PATH=`pwd`

if [ $# -lt 1 ]; then
       	OPEN=true	
elif [ $1 == "open" ]; then
	OPEN=true
elif [ $1 == "close" ]; then
	OPEN=false
fi

for file in $OPEN_FILES
do
	CUR_PATH=`cat $PRO_PATH/$file`
	if [ $CUR_PATH == $CODE_PATH ]; then
		[ $OPEN == true ] && becho "Already exist" && exit 0
		rm $PRO_PATH/$file && echo "rm $file"
	fi
done

if [ $OPEN == true ]; then
	FILE_NAME=`date  "+%Y-%m-%d_%H%M%S"`
	PATH_FILE=~/work/private/propath/${FILE_NAME}.path
	echo $CODE_PATH > $PATH_FILE
	becho "new $FILE_NAME"
else
	recho "Already not exist"
	exit 0
fi
