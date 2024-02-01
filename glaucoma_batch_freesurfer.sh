#!/bin/bash

module unload freesurfer
module load freesurfer/7.4.0 fsl/6.0.7.1
export SUBJECTS_DIR=/misc/mansfield/lconcha/exp/glaucoma/fs_glaucoma




bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids
logs=/misc/mansfield/lconcha/exp/glaucoma/logs

for sID in $(glaucoma_list_subjects.sh)
do
  fcheck=${SUBJECTS_DIR}/sub-${sID}/surf/lh.white
  if [ -f $fcheck ]
  then
    echolor green "[INFO] sub-${s} already processed by freesurfer."
    echolor green "       file exists: $fcheck"
  else
    t1=${bids_dir}/sub-${sID}/anat/sub-${sID}_T1w.nii.gz
    if [ ! -f $t1 ]; then
      echolor red "[ERROR] Cannot find file: $t1"
    else
      fsl_sub -q all.q -N fs-${sID} -l $logs \
        recon-all -subjid sub-${sID} -i $t1 -all
    fi
  fi
done
