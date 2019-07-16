#!/bin/bash

if [ $1 == "q_master" ]; then
	gecho "repo init -u ssh://android.intel.com/manifests -b android/master -m r1"
	repo init -u ssh://android.intel.com/manifests -b android/master -m r1 && \
        repo sync -j5 && repo start gaofengzhx --all && \
        repo sync --force-sync -j5
elif [ $1 == "p_stable" ]; then
	gecho "repo init -u ssh://android.intel.com/manifests -b android/p/mr0/stable/bxtp_ivi/master -m r1"
	repo init -u ssh://android.intel.com/manifests -b android/p/mr0/stable/bxtp_ivi/master -m r1 && \
        repo sync -j5 && repo start gaofengzhx --all && \
        repo sync --force-sync -j5
fi
