#!/bin/bash
source `which my_do_cmd`






do_hb=0
do_muse=0



while getopts "hmb" arg
do
  case $arg in
    h)
      do_hb=1
      echolor cyan "[INFO] Will preproc HB-DWI";;
    m)
      do_muse=1
      echolor cyan "[INFO] Will preproc MUSE-DWI";;
    b)
      do_hb=1
      do_muse=1
    ;;
    *)
      echolor red "[ERROR] Unrecognized option"
      exit 2
    ;;
  esac
done
shift $((OPTIND-1))



sID=$1
bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids
nifti_dir=/misc/mansfield/lconcha/exp/glaucoma/raw
DWI_HB_full=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi.nii.gz
DWI_HB_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-hb_epi.nii.gz
DWI_MUSE_full=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi.nii.gz
DWI_MUSE_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-muse_epi.nii.gz




mkdir -p $bids_dir/derivatives/sub-${sID}/{dwi,anat}
tmpDir=$(mktemp -d)





####### Hyperband
if [ $do_hb -eq 1 ]; then
  isOK=1
  for f in $DWI_HB_full $DWI_HB_pepolar
  do
    if [ ! -f $f ]; then echolor red "[ERROR] File does not exist: $f"; isOK=0;
    else echolor white "   found: $f";fi
  done
  if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot preprocess hyperband."
  else


    echolor green "[INFO] Denoising"
    fcheck=$bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.nii.gz
    if [ ! -f $fcheck ]; then
    my_do_cmd mrconvert \
      -json_import ${DWI_HB_full%.nii.gz}.json \
      -fslgrad ${DWI_HB_full%.nii.gz}.{bvec,bval} \
      $DWI_HB_full \
      ${tmpDir}/dwi_hb.mif

      my_do_cmd dwidenoise \
        ${tmpDir}/dwi_hb.mif ${tmpDir}/dwi_hb_d.mif

      my_do_cmd mrconvert \
        -export_grad_fsl $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.{bvec,bval} \
        -json_export $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.json \
        ${tmpDir}/dwi_hb_d.mif \
        $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.nii.gz
    else echolor green "[INFO] File exists: $fcheck"; fi

    echolor green "[INFO] Pre-processing Hyperband acquisition"
    fcheck=$bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif
    if [ ! -f $fcheck ]; then
      mrconvert -json_import ${DWI_HB_full%.nii.gz}.json    \
        -coord 3 0 ${DWI_HB_full}    ${tmpDir}/HB_b0_PA.mif
      mrconvert -json_import ${DWI_HB_pepolar%.nii.gz}.json \
        -coord 3 0 ${DWI_HB_pepolar} ${tmpDir}/HB_b0_AP.mif
      mrcat -axis 3 ${tmpDir}/HB_b0_PA.mif ${tmpDir}/HB_b0_AP.mif ${tmpDir}/HB_b0_pair.mif
      my_do_cmd mrconvert \
        -json_import $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.json \
        $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.nii.gz \
        ${tmpDir}/dwi_hb_d.mif
      mkdir -p $bids_dir/derivatives/sub-${sID}/dwi/quad_hb
      dwifslpreproc \
        $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.nii.gz \
        $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif \
        -json_import $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_d.json \
        -rpe_header \
        -se_epi ${tmpDir}/HB_b0_pair.mif \
        -align_seepi \
        -eddy_options "  --data_is_shelled --slm=linear --mporder=6 --s2v_niter=5 --s2v_lambda=1 --s2v_interp=trilinear " \
        -scratch ${tmpDir} \
        -eddyqc_all $bids_dir/derivatives/sub-${sID}/dwi/quad_hb
    else echolor green "[INFO] File exists: $fcheck"; fi
  fi
fi






### MUSE
if [ $do_muse -eq 1 ]; then
  isOK=1
  for f in $DWI_MUSE_full $DWI_MUSE_pepolar
  do
    if [ ! -f $f ]; then echolor red "[ERROR] File does not exist: $f"; isOK=0;
    else echolor white "   found: $f";fi
  done
  if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot preprocess muse."
  else

  fcheck=$bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_d.nii.gz
    if [ ! -f $fcheck ]; then
    my_do_cmd mrconvert \
      -json_import ${DWI_MUSE_full%.nii.gz}.json \
      -fslgrad ${DWI_MUSE_full%.nii.gz}.{bvec,bval} \
      $DWI_MUSE_full \
      ${tmpDir}/dwi_muse.mif

      my_do_cmd dwidenoise \
        ${tmpDir}/dwi_muse.mif ${tmpDir}/dwi_muse_d.mif

      my_do_cmd mrconvert \
        -export_grad_fsl $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_d.{bvec,bval} \
        -json_export $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_d.json \
        ${tmpDir}/dwi_muse_d.mif \
        $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_d.nii.gz
    else echolor green "[INFO] File exists: $fcheck"; fi

    echolor green "[INFO] Pre-processing MUSE acquisition"
    fcheck=$bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif
    if [ ! -f $fcheck ]; then
      mrconvert -json_import ${DWI_MUSE_full%.nii.gz}.json    \
        -coord 3 0 ${DWI_MUSE_full}    ${tmpDir}/MUSE_b0_PA.mif
      mrconvert -json_import ${DWI_MUSE_pepolar%.nii.gz}.json \
        -coord 3 0 ${DWI_MUSE_pepolar} ${tmpDir}/MUSE_b0_AP.mif
      mrcat -axis 3 ${tmpDir}/MUSE_b0_PA.mif ${tmpDir}/MUSE_b0_AP.mif ${tmpDir}/MUSE_b0_pair.mif
      mkdir -p $bids_dir/derivatives/sub-${sID}/dwi/quad_muse
      
      dwifslpreproc \
        $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_d.nii.gz \
        $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif \
        -json_import $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_d.json \
        -rpe_header \
        -se_epi ${tmpDir}/MUSE_b0_pair.mif \
        -align_seepi \
        -eddy_options "  --data_is_shelled --slm=linear --mporder=6  --s2v_niter=5 --s2v_lambda=1 --s2v_interp=trilinear " \
        -scratch ${tmpDir} \
        -eddyqc_all $bids_dir/derivatives/sub-${sID}/dwi/quad_muse
          
    else echolor green "[INFO] File exists: $fcheck"; fi
  fi
fi

  rm -fR $tmpDir