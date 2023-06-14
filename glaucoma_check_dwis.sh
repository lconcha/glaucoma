#!/bin/bash

bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids

IDs=$@
if [[ "$IDs" == "all" ]]
then
  echolor green "[INFO] Checking all subjects in bids_dir"
  IDs=""
  for subj in $(ls -d ${bids_dir}/sub-*)
  do
    s=${subj#*sub-}
    IDs="$IDs $s"
  done

fi



for s in $IDs
do
    isOK=1
    sID=$(echo $s | awk -F- '{print $NF}')
    echo ""
    echolor cyan "[INFO] Checking files for sub-${sID}"


    HB=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi.nii.gz
    HB_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-hb_epi.nii.gz
    HB_de=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif


    MUSE=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi.nii.gz
    MUSE_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-muse_epi.nii.gz
    MUSE_de=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif
    for f in $HB $HB_pepolar $HB_de  $MUSE $MUSE_pepolar $MUSE_de 
    do
    if [ ! -f $f ]
    then
        echolor orange "[WARN] Missing file: $f"
    else
        echolor yellow "[INFO] Found $f"
        sz=$(mrinfo -size $f)
        echolor yellow "       Dimensions: $sz"
    fi
    done
done

