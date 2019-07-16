#!/bin/bash

CODE_PATH_FILE=~/work/auto/.path
CODE_PATHS=$(cat $CODE_PATH_FILE)

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
opt=7
TARGET=(not_exsit aosp_arm_eng aosp_arm64-eng aosp_x86-eng aosp_x86_64-eng leaf_hill-userdebug leaf_hill_acrn-userdebug gordon_peak-userdebug gordon_peak_acrn-userdebug egp_dv-userdebug cel_kbl_acrn-userdebug cel_apl-eng)

zbuild() {
	source build/envsetup.sh
	lunch $1
	./device/intel/mixins/mixin-update
	make $2 -j5
}

for CODE_PATH in $CODE_PATHS
do
	cd $CODE_PATH
	zbuild ${TARGET[$opt]} flashfiles
	cd -

done
