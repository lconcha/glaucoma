#!/bin/bash

bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids


for s in $(ls -d ${bids_dir}/sub-*)
do

  isOK=1
  sID=$(echo $s | awk -F- '{print $NF}')
  echo ""
  echolor cyan "[INFO] Checking files for sub-${sID}"
  

  # Check preprocessed files
  HB_de=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif
  MUSE_de=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif
  for f in $HB_de $MUSE_de
  do
    if [ ! -f $f ]
    then
      echolor orange "[WARN] Missing preprocessing file: $f"
      isOK=0
    fi
  done

  # Check registration and masks
  HB_mask=${bids_dir}/derivatives/sub-${sID}/dwi/HB_mask_with_eyes.nii.gz
  MUSE_mask=${bids_dir}/derivatives/sub-${sID}/dwi/MUSE_mask_with_eyes.nii.gz
  atlas2sub=${bids_dir}/derivatives/sub-${sID}/anat/atlas2sub.nii.gz
  for f in $HB_mask $MUSE_mask $atlas2sub
    do
    if [ ! -f $f ]
    then
        echolor orange "[WARN] Missing reg/mask file: $f"
        isOK=0
    fi
  done

  if [ $isOK -eq 1 ]
  then
    echolor green "[INFO] All OK with sub-${sID}"
  fi

done