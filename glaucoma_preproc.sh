#!/bin/bash
source `which my_do_cmd`

sID=$1


nifti_dir=/misc/mansfield/lconcha/exp/glaucoma/raw
preproc_dir=/misc/mansfield/lconcha/exp/glaucoma/preproc

DWI_HB_full=$(find $nifti_dir/${sID} -name ${sID}_*_DWI_HB.nii.gz)
DWI_HB_pepolar=$(find $nifti_dir/${sID} -name ${sID}_*_DWI_HB_pepolar.nii.gz)
slspec=${DWI_HB_full%.nii.gz}_slspec.txt
HB_bvec=${DWI_HB_full%.nii.gz}.bvec
HB_bval=${DWI_HB_full%.nii.gz}.bval
DWI_MUSE_full=$(find $nifti_dir/${sID} -name ${sID}_*_DWI-MUSE.nii.gz)
DWI_MUSE_pepolar=$(find $nifti_dir/${sID} -name ${sID}_*_DWI-MUSE_pepolar.nii.gz)




isOK=1
for f in $DWI_HB_full $DWI_HB_pepolar $slspec $HB_bvec $HB_bval
do
  if [ ! -f $f ]; then echolor red "[ERROR] File does not exist: $f"; isOK=0;
  else echolor white "   found: $f";fi
done
if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot continue."; exit 2;fi


mkdir -p $preproc_dir/${sID}
tmpDir=$(mktemp -d)

my_do_cmd dwidenoise \
  ${DWI_HB_full} $preproc_dir/${sID}/dwi_HB_d.mif


mrconvert -coord 3 0 ${DWI_HB_full}    ${tmpDir}/HB_b0_PA.nii
mrconvert -coord 3 0 ${DWI_HB_pepolar} ${tmpDir}/HB_b0_AP.nii
mrcat -axis 3 ${tmpDir}/HB_b0_PA.nii ${tmpDir}/HB_b0_AP.nii ${tmpDir}/HB_b0_pair.nii
mrinfo ${tmpDir}/HB_b0_pair.nii


dwifslpreproc \
  -fslgrad $HB_bvec $HB_bval \
  $preproc_dir/${sID}/dwi_HB_d.mif \
  $preproc_dir/${sID}/dwi_HB_de.mif \
  -rpe_pair \
  -se_epi ${tmpDir}/HB_b0_pair.nii \
  -pe_dir pa \
  -align_seepi \
  -eddy_options "  --data_is_shelled --slm=linear" \
  -eddy_slspec $slspec \
  -scratch ${tmpDir} \
  -eddyqc_text $preproc_dir/${sID}



  rm -fR $tmpDir