#!/bin/bash
source `which my_do_cmd`

sID=$1


bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids
nifti_dir=/misc/mansfield/lconcha/exp/glaucoma/raw
#preproc_dir=/misc/mansfield/lconcha/exp/glaucoma/preproc

DWI_HB_full=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi.nii.gz
DWI_HB_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-hb_epi.nii.gz
DWI_MUSE_full=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi.nii.gz
DWI_MUSE_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-muse_epi.nii.gz

#slspec=${DWI_HB_full%.nii.gz}_slspec.txt
#HB_bvec=${DWI_HB_full%.nii.gz}.bvec
#HB_bval=${DWI_HB_full%.nii.gz}.bval




isOK=1
for f in $DWI_HB_full $DWI_HB_pepolar $DWI_MUSE_full $DWI_MUSE_pepolar
do
  if [ ! -f $f ]; then echolor red "[ERROR] File does not exist: $f"; isOK=0;
  else echolor white "   found: $f";fi
done
if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot continue."; exit 2;fi


mkdir -p $bids_dir/derivatives/sub-${sID}/{dwi,anat}


tmpDir=$(mktemp -d)

my_do_cmd mrconvert \
  -json_import ${DWI_HB_full%.nii.gz}.json \
  -fslgrad ${DWI_HB_full%.nii.gz}.{bvec,bval} \
  $DWI_HB_full \
  ${tmpDir}/dwi_hb.mif


fcheck=$bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.nii.gz
if [ ! -f $fcheck ]; then
  my_do_cmd dwidenoise \
    ${tmpDir}/dwi_hb.mif ${tmpDir}/dwi_hb_d.mif
  my_do_cmd mrconvert \
    -export_grad_fsl $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.{bvec,bval} \
    -json_export $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.json \
    ${tmpDir}/dwi_hb_d.mif \
    $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi




mrconvert -coord 3 0 ${DWI_HB_full}    ${tmpDir}/HB_b0_PA.nii
mrconvert -coord 3 0 ${DWI_HB_pepolar} ${tmpDir}/HB_b0_AP.nii
mrcat -axis 3 ${tmpDir}/HB_b0_PA.nii ${tmpDir}/HB_b0_AP.nii ${tmpDir}/HB_b0_pair.nii


readout_time=$(jq -r .TotalReadoutTime $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.json) 

dwifslpreproc \
  -fslgrad $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.{bvec,bval} \
  $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.nii.gz \
  $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.nii.gz \
  -pe_dir pa \
  -rpe_pair \
  -readout_time $readout_time \
  -se_epi ${tmpDir}/HB_b0_pair.nii \
  -align_seepi \
  -eddy_options "  --data_is_shelled --slm=linear" \
  -scratch ${tmpDir} \
  -eddyqc_text $bids_dir/derivatives/sub-${sID}/dwi

#-eddy_slspec $slspec \

# -json_import $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.json \
    


  rm -fR $tmpDir