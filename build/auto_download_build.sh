#!/bin/bash
BRANCH_NAME="q_master"
CODE_PATH=~/work/auto/
TIMESTAMP=`date +%m%d`

# Lunch menu... pick a combo:
#    1. aosp_arm-eng
#    2. aosp_arm64-eng
#    3. aosp_x86-eng
#    4. aosp_x86_64-eng
#    5. leaf_hill-userdebug
#    6. leaf_hill_acrn-userdebug
#    7. gordon_peak-userdebug
#    8. gordon_peak_acrn-userdebug
#    9. egp_dv-userdebug
#    10. cel_kbl_acrn-userdebug
#    11. cel_apl-eng
#    12 apl_nuc-userdebug
#    13. ehl_presi-userdebug
#    14. icl_rvp-userdebug
opt=7
TARGET=(not_exsit aosp_arm_eng aosp_arm64-eng aosp_x86-eng aosp_x86_64-eng leaf_hill-userdebug leaf_hill_acrn-userdebug gordon_peak-userdebug gordon_peak_acrn-userdebug egp_dv-userdebug cel_kbl_acrn-userdebug cel_apl-eng apl_nuc-userdebug ehl_presi-userdebug icl_rvp-userdebug)

gecho ${TARGET[${opt}]}

zbuild() {
	source build/envsetup.sh
	lunch $1
	./device/intel/mixins/mixin-update
	make $2 -j5
}

# echo $DIR_NAME
# download code
INDEX=1
index=0
CODE_DIR_GROUP=()
for i in $BRANCH_NAME
do
	CODE_DIR=${CODE_PATH}${i}_$TIMESTAMP
    while true
    do
	    mkdir $CODE_DIR && break || \
            CODE_DIR=${CODE_PATH}${i}_${TIMESTAMP}${INDEX} && INDEX=`expr $INDEX + 1`
    done
    gecho $CODE_DIR
	cd $CODE_DIR
        CODE_DIR_GROUP[${index}]=$CODE_DIR && index=`expr $index + 1`
    	zepo.sh $i
	cd -
done

# build
for i in ${CODE_DIR_GROUP[@]}
do
	cd $i
        becho $i
		zbuild ${TARGET[$opt]} flashfiles
	cd -
done
