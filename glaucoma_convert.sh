#!/bin/bash
source `which my_do_cmd`

if [ -z $(which dcm2bids) ]
then
    echolor red "[ERROR] Don't forget to activate dcm2bids conda environment:"
    echolor red "        conda activate dcm2bids"
    exit 2
fi


dicom_dir=$1
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
