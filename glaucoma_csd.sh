#!/bin/bash
source `which my_do_cmd`



do_hb=0
do_muse=0
tmp_cleanup=""


while getopts "hmbt" arg
do
  case $arg in
    h)
      do_hb=1
      echolor cyan "[INFO] Will process HB-DWI";;
    m)
      do_muse=1
      echolor cyan "[INFO] Will process MUSE-DWI";;
    b)
      do_hb=1
      do_muse=1
    ;;
    t)
      tmp_cleanup=" -nocleanup "
      echolor cyan "[INFO] Will retain temporary directory."
    ;;
    *)
      echolor red "[ERROR] Unrecognized option"
      exit 2
    ;;
  esac
done
shift $((OPTIND-1))


if [ $do_hb -eq 0 -a $do_muse -eq 0 ]
then
  echolor red "[ERROR] Nothing to process. You need to specify at least one of -m or -h (or -b for both)"
  exit 2
fi



sID=$1
bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids



function runcsd() {
   dwi=$1
   mask=$2
   bids_dir=$3
   sID=$4
   acq=$5
   echolor green "[INFO] Processing CSD..."
   my_do_cmd dwi2response dhollander \
     -mask $mask \
     $dwi \
     ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_response-wm.txt \
     ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_response-gm.txt \
     ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_response-csf.txt
   my_do_cmd dwi2fod msmt_csd \
     -mask $mask \
     $dwi \
     ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_response-wm.txt ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_fod-wm.mif \
     ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_response-gm.txt ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_fod-gm.mif \
     ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_response-csf.txt ${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-${acq}_fod-csf.mif
}



if [ $do_hb -eq 1 ]; then
  dwi=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif
  mask=${bids_dir}/derivatives/sub-${sID}/dwi/HB_mask_with_eyes.nii.gz
  isOK=1
  for f in $dwi $mask
  do
    if [ ! -f $f ]; then echolor red "[ERROR] File does not exist: $f"; isOK=0;
    else echolor white "   found: $f";fi
  done
  if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot process hyperband."
  else
     runcsd $dwi $mask $bids_dir $sID hb
  fi
fi


if [ $do_muse -eq 1 ]; then
  dwi=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif
  mask=${bids_dir}/derivatives/sub-${sID}/dwi/muse_mask_brain+eyes.nii.gz
  isOK=1
  for f in $dwi $mask
  do
    if [ ! -f $f ]; then echolor red "[ERROR] File does not exist: $f"; isOK=0;
    else echolor white "   found: $f";fi
  done
  if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot process hyperband."
  else
     runcsd $dwi $mask $bids_dir $sID muse
  fi
fi