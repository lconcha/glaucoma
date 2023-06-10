#!/bin/bash

sID=$1
out_dir=$2


bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids

mrview ${bids_dir}/anat/sub-${sID}_T1w.nii.gz


mrview -plane 0 -interpolation true -capture.folder $out_dir -capture.prefix sag_ 