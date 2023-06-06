#!/bin/bash
source `which my_do_cmd`
fakeflag=""


sID=$1
bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids

# t1=$1
# dwi_HB=$2;   # corrected
# dwi_MUSE=$3; # corrected
# outbase=$4

t1=${bids_dir}/sub-${sID}/anat/sub-4375_T1w.nii.gz
dwi_HB=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif
dwi_MUSE=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif
outbase=${bids_dir}/derivatives/sub-${sID}
force=0
keep_tmp=1


# while getopts "tf" options; do
#   case "$options" in
#     f)
#       force=1;  echolor green "[INFO] Will overwrite outputs"; shift
#       ;;
#     t)
#       keep_tmp=1;  echolor green "[INFO] Will keep temp directory"; shift
#     ;;
#   esac
# done
#shift $((OPTIND-1))


isOK=1
for f in $t1 $dwi_HB $dwi_MUSE
do
  if [ ! -f $f ]; then
    echolor red "[ERROR] Cannot find file: $f"
    isOK=0
  else
    echolor cyan "[INFO] Found file: $f"
  fi
done
if [ $isOK -eq 0 ]; then echolor "[ERROR] Cannot continue";exit 2; fi



echo "
T1      : $t1
dwi_HB  : $dwi_HB
outbase : $outbase
"



tmpDir=$(mktemp -d)

atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
atlas_fa=$FSLDIR/data/standard/FSL_HCP1065_FA_2mm.nii.gz

#mask_eyes=/misc/mansfield/lconcha/exp/glaucoma/eyes_mask_MNI_2mm.nii.gz
mask_eyes=/misc/mansfield/lconcha/exp/glaucoma/MNI152_T1_2mm_eyes_opticNerves_mask.nii.gz


echolor cyan "[INFO] Removing neck"
#fcheck=${outbase}



echolor cyan "[INFO] Resampling to 2 mm"
my_do_cmd $fakeflag mrgrid \
  -vox 2 \
  -interp nearest \
  $t1 \
  regrid \
  ${tmpDir}/t1_2mm.nii


fcheck=${outbase}/dwi/sub2atlas_lin.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Running FLIRT"
my_do_cmd $fakeflag flirt \
  -ref  $atlas_t1 \
  -in   ${tmpDir}/t1_2mm.nii \
  -out  ${outbase}/dwi/sub2atlas_lin \
  -omat ${outbase}/dwi/sub2atlas_lin.mat
else echolor green "[INFO] File exists: $fcheck"; fi
  

fcheck=${outbase}/dwi/sub2atlas_nlin_field.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Running FNIRT"
my_do_cmd $fakeflag fnirt \
  --ref=$atlas_t1 \
  --in=${tmpDir}/t1_2mm.nii \
  --fout=${outbase}/dwi/sub2atlas_nlin_field \
  --iout=${outbase}/dwi/sub2atlas_nlin \
  --aff=${outbase}/dwi/sub2atlas_lin.mat \
  -v
else echolor green "[INFO] File exists: $fcheck"; fi


fcheck=${outbase}/dwi/atlas2sub_nlin_field.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Inverting warp"
my_do_cmd $fakeflag invwarp \
  -w ${outbase}/dwi/sub2atlas_nlin_field \
  -o ${outbase}/dwi/atlas2sub_nlin_field \
  -r ${tmpDir}/t1_2mm.nii \
  -v
else echolor green "[INFO] File exists: $fcheck"; fi

fcheck=${outbase}/dwi/atlas2sub_mask_eyes.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Putting mask in t1 native space"
my_do_cmd $fakeflag applywarp \
  -i $mask_eyes \
  -o ${outbase}/dwi/atlas2sub_mask_eyes \
  -r $t1 \
  -w ${outbase}/dwi/atlas2sub_nlin_field \
  --interp=nn \
  -v  
else echolor green "[INFO] File exists: $fcheck"; fi


echolor cyan "[INFO] -------- DTI for masking ------------"
my_do_cmd $fakeflag dwi2mask \
  $dwi_HB ${tmpDir}/dwi_HB_mask.mif  

dwiextract \
  -shell 800 \
  $dwi_HB - | \
mrmath -axis 3 - mean - |\
mrcalc - ${tmpDir}/dwi_HB_mask.mif -mul \
  ${tmpDir}/HB_av_b800_masked.nii

my_do_cmd $fakeflag bet \
  $t1 \
  ${tmpDir}/t1_m \
  -m

fcheck=${outbase}/dwi/t12dwi.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag flirt \
  -ref ${tmpDir}/HB_av_b800_masked.nii \
  -in  ${tmpDir}/t1_m \
  -out ${outbase}/dwi/t12dwi.nii.gz \
  -omat ${outbase}/dwi/t12dwi.mat
else echolor green "[INFO] File exists: $fcheck"; fi

fcheck=${outbase}/dwi/dwi_HB_mask_with_eyes.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd flirt \
  -ref ${tmpDir}/HB_av_b800_masked.nii \
  -in ${outbase}/dwi/atlas2sub_mask_eyes \
  -applyxfm -init ${outbase}/dwi/t12dwi.mat \
  -out ${outbase}/dwi/dwi_HB_mask_eyes.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi


dwi2tensor -mask ${outbase}/dwi/dwi_HB_mask_eyes.nii.gz $dwi_HB - |\
tensor2metric -fa ${tmpDir}/fa.mif -adc ${tmpDir}/adc.mif -

mrcalc $(mrcalc ${tmpDir}/fa.mif 0.1 -gt -) $(mrcalc ${tmpDir}/fa.mif 1 -lt -) -and ${tmpDir}/fa_ok.mif
mrcalc $(mrcalc ${tmpDir}/adc.mif 0.0001 -gt -) $(mrcalc ${tmpDir}/adc.mif 0.01 -lt -) -and ${tmpDir}/adc_ok.mif
mrcalc ${tmpDir}/*_ok.mif -mul \
  ${outbase}/dwi/dwi_HB_mask_eyes.nii.gz -mul 0 -gt \
  ${tmpDir}/dwi_HB_mask.mif  -or \
  ${outbase}/dwi/dwi_HB_mask_with_eyes_clean.nii.gz


echolor cyan "[INFO] ---------- Working on MUSE DWI ----------"
dwiextract -bzero $dwi_MUSE - | mrmath -axis 3 - mean ${tmpDir}/MUSE_av_b0.nii
dwiextract -bzero $dwi_HB   - | mrmath -axis 3 - mean ${tmpDir}/HB_av_b0.nii

dwi2mask $dwi_MUSE ${tmpDir}/MUSE_mask.nii
mrcalc ${tmpDir}/MUSE_av_b0.nii ${tmpDir}/MUSE_mask.nii -mul ${tmpDir}/MUSE_masked.nii


# my_do_cmd $fakeflag flirt \
#   -ref  ${tmpDir}/MUSE_av_b0.nii \
#   -in   ${tmpDir}/HB_av_b0.nii \
#   -out  ${outbase}/dwi/MUSE2HB_b0.nii.gz \
#   -omat ${outbase}/dwi/MUSE2HB.mat


fcheck=${outbase}/dwi/T12MUSE.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag flirt \
  -in   ${tmpDir}/t1_m \
  -ref  ${tmpDir}/MUSE_masked.nii \
  -out  ${outbase}/dwi/T12MUSE.nii.gz \
  -omat ${outbase}/dwi/T12MUSE.mat
else echolor green "[INFO] File exists: $fcheck"; fi



fcheck=${outbase}/dwi/T12MUSE.mat
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd flirt \
  -ref ${tmpDir}/MUSE_masked.nii \
  -in ${outbase}/dwi/atlas2sub_mask_eyes \
  -applyxfm -init ${outbase}/dwi/T12MUSE.mat \
  -out ${outbase}/dwi/MUSE_mask_eyes.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi


dwi2tensor -mask ${outbase}/dwi/MUSE_mask_eyes.nii.gz $dwi_MUSE - |\
tensor2metric -fa ${tmpDir}/MUSE_fa.mif -adc ${tmpDir}/MUSE_adc.mif -
mrcalc $(mrcalc ${tmpDir}/MUSE_fa.mif 0.1 -gt -)     $(mrcalc ${tmpDir}/MUSE_fa.mif 1 -lt -) -and ${tmpDir}/MUSE_fa_ok.mif
mrcalc $(mrcalc ${tmpDir}/MUSE_adc.mif 0.0001 -gt -) $(mrcalc ${tmpDir}/MUSE_adc.mif 0.01 -lt -) -and ${tmpDir}/MUSE_adc_ok.mif
mrcalc ${tmpDir}/MUSE_*_ok.mif -mul \
  ${outbase}/dwi/MUSE_mask_eyes.nii.gz -mul 0 -gt \
  ${tmpDir}/MUSE_mask.nii  -or \
  ${outbase}/dwi/dwi_MUSE_mask_with_eyes_clean.nii.gz


if [ $keep_tmp -eq 1 ]
then
  echolor yellow "[INFO] Not deleting temp directory $tmpDir"
else
  rm -fR $tmpDir
fi
