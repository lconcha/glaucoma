#!/bin/bash
source `which my_do_cmd`
fakeflag=""

t1=$1
fa=$2
outbase=$3

tmpDir=$(mktemp -d)

atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
atlas_fa=$FSLDIR/data/standard/FSL_HCP1065_FA_2mm.nii.gz

mask_with_eyes=/misc/mansfield/lconcha/exp/glaucoma/MNI152_T1_2mm_brain_mask_dil_withEyes.nii.gz

echolor cyan "[INFO] Resampling to 2 mm"
my_do_cmd $fakeflag mrgrid \
  -vox 2 \
  $t1 \
  regrid \
  ${tmpDir}/t1_2mm.nii


echolor cyan "[INFO] Running FLIRT"
my_do_cmd $fakeflag flirt \
  -ref  $atlas_t1 \
  -in   ${tmpDir}/t1_2mm.nii \
  -out  ${outbase}_sub2atlas_lin \
  -omat ${outbase}_sub2atlas_lin.mat
  
echolor cyan "[INFO] Running FNIRT"
my_do_cmd $fakeflag fnirt \
  --ref=$atlas_t1 \
  --in=${tmpDir}/t1_2mm.nii \
  --fout=${outbase}_sub2atlas_nlin_field \
  --iout=${outbase}_sub2atlas_nlin \
  --aff=${outbase}_sub2atlas_lin.mat \
  -v

my_do_cmd $fakeflag invwarp \
  -w ${outbase}_sub2atlas_nlin_field \
  -o ${outbase}_atlas2sub_nlin_field \
  -r ${tmpDir}/t1_2mm.nii \
  -v
  
my_do_cmd $fakeflag applywarp \
  -i $mask_with_eyes \
  -o ${outbase}_atlas2sub_mask_with_eyes \
  -r $t1 \
  -w ${outbase}_atlas2sub_nlin_field \
  --interp=nn \
  -v  
#  -r ${tmpDir}/t1_2mm.nii \
  


rm -fR $tmpDir
