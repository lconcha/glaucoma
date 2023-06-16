#!/bin/bash

# quick little function to list all subjects in bids_dir
# the intention is to feed this list to some other function for batch processing.
#
# example:
#
# for s in $(glaucoma_list_subjects.sh); do echo "glaucoma_reg_and_mask.sh $s";done

bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids

subject_list=""
for s in $(ls -d ${bids_dir}/sub-*)
do
  sShort=$(basename $s)
  sID=${sShort#sub-}
  subject_list="$subject_list $sID"
done

echo $subject_list