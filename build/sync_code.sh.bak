#!/bin/bash

PRO_PATH=~/work/private/propath/
CODE_FILES=`ls $PRO_PATH`
REPO=.repo
LOG_FILE=~/work/private/.prolog

DATE=`date`
echo "=================$DATE===================" >> $LOG_FILE
RM_DOUBLE_PATH() {
	L_CODE_FILES=`ls $PRO_PATH`
	FILE=$1
	if [ -f $PRO_PATH$FILE ]; then
		L_PATH=`cat $PRO_PATH$FILE`
	fi
	for i in $L_CODE_FILES
	do
		if [ ! -f $PRO_PATH$i ]; then
			continue
		fi
		DOUBLE_PATH=`cat $PRO_PATH$i`
		if [ $DOUBLE_PATH == $L_PATH ]; then
			[ $i != $FILE ] && rm $PRO_PATH$i && echo "$i same $FILE rm $i" >> $LOG_FILE
		fi
	done
} 

for i in $CODE_FILES
do
	if [ ! -f $PRO_PATH$i ]; then
		continue
	fi
	CODE_PATH=`cat $PRO_PATH$i`
	RM_DOUBLE_PATH $i
	if [ ! -d $CODE_PATH ]; then
		echo "NO THIS PATH:$CODE_PATH rm $i" >> $LOG_FILE
		rm $PRO_PATH$i
		continue
	fi	
	if [ ! -d $CODE_PATH/$REPO ]; then
		echo "THIS PATH NO CODE:$CODE_PATH rm $i" >> $LOG_FILE
		rm $PRO_PATH$i
		continue
	fi
	cd $CODE_PATH
	pwd
	repo sync --force-sync -j5
	cd -
	echo "In $CODE_PATH UPDATE CODE" >> $LOG_FILE
done
