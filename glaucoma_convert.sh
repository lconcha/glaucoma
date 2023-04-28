#!/bin/bash
source `which my_do_cmd`

#dicom_dir=/misc/mansfield/lconcha/exp/glaucoma/DICOMs
dicom_dir=$1
nifti_dir=/misc/mansfield/lconcha/exp/glaucoma/raw
bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids
config=/misc/mansfield/lconcha/software/glaucoma/glaucoma_dcm2bids_config.json

# find the first dicom file to get subject ID from it
dcm=$(find $dicom_dir -name IM*0001.dcm | head -n 1)
sID=$(dcminfo -tag 0010 0020 "$dcm" | awk '{print $2}')


dcm2bids -d $dicom_dir \
         -p $sID \
         -c $config \
         -o $bids_dir \
         -l DEBUG \
         --forceDcm2niix



# my_do_cmd mkdir $nifti_dir/$sID
# my_do_cmd  dcm2niix \
#   -i y \
#   -z n \
#   -f %i_%s_%d \
#   -o $nifti_dir/${sID} \
#   -progress y \
#   -b y \
#   -z y \
#   $dicom_dir


# DWI_HB_full=$(find $nifti_dir/${sID} -name ${sID}_*_DWI_HB.nii.gz)
# DWI_HB_pepolar=$(find $nifti_dir/${sID} -name ${sID}_*_DWI_HB_pepolar.nii.gz)
# DWI_MUSE_full=$(find $nifti_dir/${sID} -name ${sID}_*_DWI-MUSE.nii.gz)
# DWI_MUSE_pepolar=$(find $nifti_dir/${sID} -name ${sID}_*_DWI-MUSE_pepolar.nii.gz)


# echo "
# DWI_HB_full      : $DWI_HB_full
# DWI_HB_pepolar   : $DWI_HB_pepolar
# DWI_MUSE_full    : $DWI_MUSE_full
# DWI_MUSE_pepolar : $DWI_MUSE_pepolar
# "


# isOK=1
# for f in $DWI_HB_full $DWI_HB_pepolar $DWI_MUSE_full $DWI_HB_pepolar
# do
#   if [ ! -f $f ]; then echolor red "[ERROR] File does not exist: $f"; isOK=0;fi
# done
# if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot continue."; exit 2;fi



# echolor green "[INFO] BIDSifying files"
# mkdir -p $bids_dir/sub-${sID}/{dwi,anat}
# mkdir -p $bids_dir/derivatives/sub-${sID}/{dwi,anat}
# mv -v $DWI_HB_full $bids_dir/sub-${sID}/dwi/sub-${sID}_acq-HB_dwi.nii.gz
# mv -v ${DWI_HB_full%.bvec} $bids_dir/sub-${sID}/dwi/sub-${sID}_acq-HB_dwi.bvec
# mv -v ${DWI_HB_full%.bval} $bids_dir/sub-${sID}/dwi/sub-${sID}_acq-HB_dwi.bval

# my_do_cmd glaucoma_write_slspec.sh ${DWI_HB_full}