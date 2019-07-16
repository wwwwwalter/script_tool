#!/bin/bash
_XH=

_XHG=(not_exist gordon_peak apl_nuc leaf_hill)
if [ $# == 0 ]; then
    printf "please choose:\n"
    printf "[1] gordon_peak\n"
    printf "[2] apl_nuc\n"
    printf "[3] leaf_hill\n"
    read  -p "input:" xh
    _XH=${_XHG[${xh}]}
else
    _XH=$1
fi

gecho $_XH

GET_FLASH() {
    awk '{print "fastboot " $0}' installer.cmd > flash.sh
    chmod 777 flash.sh
}

if [ $_XH == ${_XHG[1]} ]; then     # gordon_peak
    echo "flash" $_XH
    cflasher -f flash.json -c blank_gr_mrb_b1
elif [ $_XH == ${_XHG[2]} ]; then   # apl_nuc
    echo "flash" $_XH
    GET_FLASH
    ./flash.sh
elif [ $_XH == ${_XHG[3]} ]; then     # leaf_hill
    echo "flash" $_XH
    cflasher -f flash.json -c blank_lfh_a0
fi
