#!/bin/bash

qsiprep=/misc/mansfield/lconcha/containers/qsiprep_sandbox
bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids
qsiprep_output=/misc/mansfield/lconcha/exp/glaucoma/qsiprep_output
fs_license=/home/inb/lconcha/fmrilab_software/freesurfer_7.0/license.txt
work_dir=/misc/mansfield/lconcha/exp/glaucoma/work

sID=$1


echo singularity run \
  -B /misc/mansfield:/misc/mansfield \
  --nv \
  $qsiprep \
  --acquisition_type hb \
  --separate_all_dwis \
  --fs-license-file $fs_license \
  --work-dir $work_dir \
  --participant_label $sID \
  --output-resolution 2 \
  $bids_dir \
  $qsiprep_output \
  participant
