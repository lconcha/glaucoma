#!/bin/bash
source `which my_do_cmd`


designer_container=/home/inb/soporte/lanirem_software/containers/designer2.sif


do_hb=0
do_muse=0
tmp_cleanup=""


while getopts "hmbt" arg
do
  case $arg in
    h)
      do_hb=1
      echolor cyan "[INFO] Will start to preproc HB-DWI";;
    m)
      do_muse=1
      echolor cyan "[INFO] Will start to preproc MUSE-DWI";;
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
  echolor red "[ERROR] Nothing to preprocess. You need to specify at least one of -m or -h (or -b for both)"
  exit 2
fi



sID=$1
#bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids
bids_dir=/misc/mansfield/lconcha/exp/EsclerosisTuberosa/bids
DWI_HB_full=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi.nii.gz
DWI_HB_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-hb_epi.nii.gz
DWI_MUSE_full=${bids_dir}/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi.nii.gz
DWI_MUSE_pepolar=${bids_dir}/sub-${sID}/fmap/sub-${sID}_acq-muse_epi.nii.gz




mkdir -p $bids_dir/derivatives/sub-${sID}/{dwi,anat}
tmpDir=$(mktemp -d)
echolor cyan "[INFO] temp dir is $tmpDir"





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

    echolor green "[INFO] Pre-processing Hyperband acquisition"
    fcheck=$bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de_designer.mif
    if [ ! -f $fcheck ]; then
        singularity run --nv -B $bids_dir $designer_container designer \
            -eddy \
            -mask \
            -denoise \
            -rpe_pair $DWI_HB_pepolar \
            -pe_dir AP \
            $DWI_HB_full \
            ${tmpDir}/outputdesigner_hb.nii
        mrconvert \
          -fslgrad ${tmpDir}/outputdesigner_hb.{bvec,bval} \
          ${tmpDir}/outputdesigner_hb.nii \
          $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de_designer.mif
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

  fcheck=$bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de_designer.nii.gz
    if [ ! -f $fcheck ]; then
     singularity run --nv -B $bids_dir $designer_container designer \
        -eddy \
        -mask \
        -patch2self \
        -rpe_pair $DWI_MUSE_pepolar \
        -pe_dir AP \
        $DWI_MUSE_full \
        ${tmpDir}/outputdesigner_muse.nii

        mrconvert \
          -fslgrad ${tmpDir}/outputdesigner_muse.{bvec,bval} \
          ${tmpDir}/outputdesigner_muse.nii \
          $bids_dir/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de_designer.mif
    else 
      echolor green "[INFO] File exists: $fcheck"
    fi
  fi
fi


if [ -z $tmp_cleanup ]; then
  rm -fR $tmpDir
fi