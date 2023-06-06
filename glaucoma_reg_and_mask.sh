#!/bin/bash
source `which my_do_cmd`
fakeflag=""


sID=$1


synthstrip=/misc/mansfield/lconcha/containers/synthstrip-singularity
bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids



# t1=$1
# dwi_HB=$2;   # corrected
# dwi_MUSE=$3; # corrected
# outbase=$4

t1=${bids_dir}/sub-${sID}/anat/sub-${sID}_T1w.nii.gz
dwi_HB=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif
dwi_MUSE=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif
outbase=${bids_dir}/derivatives/sub-${sID}
force=0
keep_tmp=1

t1_resolution=$(mrinfo -spacing ${outbase}/anat/t1_noneck.nii.gz | tr ' ' ',')
  

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
if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot continue";exit 2; fi



echo "
T1      : $t1
dwi_HB  : $dwi_HB
outbase : $outbase
"



# tmpDir=$(mktemp -d)

atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz
atlas_fa=$FSLDIR/data/standard/FSL_HCP1065_FA_2mm.nii.gz

#mask_eyes=/misc/mansfield/lconcha/exp/glaucoma/eyes_mask_MNI_2mm.nii.gz
mask_eyes=/misc/mansfield/lconcha/exp/glaucoma/MNI152_T1_2mm_eyes_opticNerves_mask.nii.gz


echolor cyan "[INFO] Removing neck"
fcheck=${outbase}/anat/t1_noneck.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  my_do_cmd $fakeflag robustfov -i $t1 -r ${outbase}/anat/t1_noneck.nii.gz
else echolor green "[INFO] File exists: $fcheck"; t1=$fcheck; fi
t1=${outbase}/anat/t1_noneck.nii.gz


echolor cyan "[INFO] Brain mask for T1 via sytnthstrip"
fcheck=${outbase}/anat/t1_brain.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  $synthstrip --no-csf \
    -i $t1 \
    -o ${outbase}/anat/t1_brain.nii.gz \
    -m ${outbase}/anat/t1_mask.nii.gz
else
  echolor green "[INFO] File exists: $fcheck"
fi
t1=${outbase}/anat/t1_brain.nii.gz


echolor cyan "[INFO] Resampling to 2 mm"
fcheck=${outbase}/anat/t1_2mm_brain.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag mrgrid \
  -vox 2 \
  -interp nearest \
  $t1 \
  regrid \
  ${outbase}/anat/t1_2mm_brain.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi


fcheck=${outbase}/anat/sub2atlas_lin.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Running FLIRT to the skull-stripped atlas"
echolor cyan "[INFO] Atlas is: $atlas_t1"
my_do_cmd $fakeflag flirt \
  -ref  $atlas_t1 \
  -in   ${outbase}/anat/t1_2mm_brain.nii.gz \
  -out  ${outbase}/anat/sub2atlas_lin \
  -omat ${outbase}/anat/sub2atlas_lin.mat
else echolor green "[INFO] File exists: $fcheck"; fi
  


fcheck=${outbase}/anat/sub2atlas_nlin_field.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Running FNIRT to the __non-skull-stripped__ atlas"
atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
echolor cyan "[INFO] Atlas is: $atlas_t1"
my_do_cmd $fakeflag fnirt \
  --ref=$atlas_t1 \
  --in=${outbase}/anat/t1_2mm_brain.nii.gz \
  --fout=${outbase}/anat/sub2atlas_nlin_field \
  --iout=${outbase}/anat/sub2atlas_nlin \
  --aff=${outbase}/anat/sub2atlas_lin.mat \
  -v
else echolor green "[INFO] File exists: $fcheck"; fi


fcheck=${outbase}/anat/atlas2sub_nlin_field.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Inverting warp"
my_do_cmd $fakeflag invwarp \
  -w ${outbase}/anat/sub2atlas_nlin_field \
  -o ${outbase}/anat/atlas2sub_nlin_field \
  -r ${outbase}/anat/t1_2mm_brain.nii.gz \
  -v
else echolor green "[INFO] File exists: $fcheck"; fi

fcheck=${outbase}/anat/atlas2sub_mask_eyes.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Putting mask in t1 native space"
my_do_cmd $fakeflag applywarp \
  -i $mask_eyes \
  -o ${outbase}/anat/atlas2sub_mask_eyes \
  -r $t1 \
  -w ${outbase}/anat/atlas2sub_nlin_field \
  --interp=nn \
  -v  
else echolor green "[INFO] File exists: $fcheck"; fi

fcheck=${outbase}/anat/atlas2sub.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Putting atlas in t1 native space"
atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
echolor cyan "[INFO] Atlas is: $atlas_t1"
my_do_cmd $fakeflag applywarp \
  -i $atlas_t1 \
  -o ${outbase}/anat/atlas2sub \
  -r $t1 \
  -w ${outbase}/anat/atlas2sub_nlin_field \
  --interp=nn \
  -v  
else echolor green "[INFO] File exists: $fcheck"; fi



echolor cyan "[INFO] -------- DTI masking ------------"
fcheck=${outbase}/dwi/HB_av_b900_masked.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  my_do_cmd $fakeflag dwi2mask \
    $dwi_HB ${outbase}/dwi/HB_mask.mif
  dwiextract \
    -shell 800 \
    $dwi_HB - | \
  mrmath -axis 3 - mean - |\
  mrcalc - ${outbase}/dwi/HB_mask.mif -mul \
    ${outbase}/dwi/HB_av_b900_masked.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi


echolor cyan "[INFO] Registering t1 to dwi"
fcheck=${outbase}/dwi/t12dwi.nii.gz
  if [ ! -f $fcheck -o $force -eq 1 ]; then
  my_do_cmd $fakeflag flirt \
    -ref ${outbase}/dwi/HB_av_b900_masked.nii.gz \
    -in  ${outbase}/anat/t1_brain.nii.gz \
    -omat ${outbase}/dwi/t12dwi.mat
  my_do_cmd $fakeflag mrgrid \
    -voxel $t1_resolution \
    ${outbase}/dwi/HB_av_b900_masked.nii.gz \
    regrid \
    ${outbase}/dwi/HB_av_b900_masked_regrid.nii.gz
  my_do_cmd $fakeflag flirt \
    -ref ${outbase}/dwi/HB_av_b900_masked_regrid.nii.gz \
    -in  ${outbase}/anat/t1_noneck.nii.gz \
    -applyxfm -init ${outbase}/dwi/t12dwi.mat \
    -out ${outbase}/dwi/t12dwi.nii.gz  
else echolor green "[INFO] File exists: $fcheck"; fi


fcheck=${outbase}/dwi/dwi_HB_mask_with_eyes.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd flirt \
  -ref ${outbase}/dwi/HB_av_b900_masked.nii.gz \
  -in ${outbase}/anat/atlas2sub_mask_eyes \
  -applyxfm -init ${outbase}/dwi/t12dwi.mat \
  -out ${outbase}/dwi/dwi_HB_mask_eyes.nii.gz
my_do_cmd mrcalc \
  ${outbase}/dwi/HB_mask.mif \
  ${outbase}/dwi/dwi_HB_mask_eyes.nii.gz \
  -or \
  ${outbase}/dwi/dwi_HB_mask_with_eyes.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi





# dwi2tensor -mask ${outbase}/dwi/dwi_HB_mask_eyes.nii.gz $dwi_HB - |\
# tensor2metric -fa ${tmpDir}/fa.mif -adc ${tmpDir}/adc.mif -

# mrcalc $(mrcalc ${tmpDir}/fa.mif 0.1 -gt -) $(mrcalc ${tmpDir}/fa.mif 1 -lt -) -and ${tmpDir}/fa_ok.mif
# mrcalc $(mrcalc ${tmpDir}/adc.mif 0.0001 -gt -) $(mrcalc ${tmpDir}/adc.mif 0.01 -lt -) -and ${tmpDir}/adc_ok.mif
# mrcalc ${tmpDir}/*_ok.mif -mul \
#   ${outbase}/dwi/dwi_HB_mask_eyes.nii.gz -mul 0 -gt \
#   ${outbase}/dwi/HB_mask.mif  -or \
#   ${outbase}/dwi/dwi_HB_mask_with_eyes_clean.nii.gz


echolor cyan "[INFO] ---------- Working on MUSE DWI ----------"

fcheck=${outbase}/dwi/MUSE_av_b0_masked.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  dwiextract -bzero $dwi_MUSE - | mrmath -quiet -axis 3 - mean ${outbase}/dwi/MUSE_av_b0.nii.gz
  dwiextract -bzero $dwi_HB   - | mrmath -quiet -axis 3 - mean ${outbase}/dwi/HB_av_b0.nii.gz
  dwi2mask $dwi_MUSE ${outbase}/dwi/MUSE_mask.nii.gz
  mrcalc ${outbase}/dwi/MUSE_av_b0.nii.gz \
    ${outbase}/dwi/MUSE_mask.nii.gz \
    -mul \
    ${outbase}/dwi/MUSE_av_b0_masked.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi




fcheck=${outbase}/dwi/HB_to_MUSE_av_b0.mat
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag flirt \
  -ref  ${outbase}/dwi/MUSE_av_b0.nii \
  -in   ${outbase}/dwi/HB_av_b0.nii \
  -out  ${outbase}/dwi/HB_to_MUSE_av_b0.nii.gz \
  -omat ${outbase}/dwi/HB_to_MUSE_av_b0.mat
else echolor green "[INFO] File exists: $fcheck"; fi



fcheck=${outbase}/dwi/t12muse.nii.gz 
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag convert_xfm \
  -omat ${outbase}/dwi/t1_to_MUSE.mat \
  -concat \
  ${outbase}/dwi/HB_to_MUSE_av_b0.mat \
  ${outbase}/dwi/t12dwi.mat
my_do_cmd flirt \
  -ref ${outbase}/dwi/MUSE_av_b0.nii.gz \
  -in  ${outbase}/anat/atlas2sub_mask_eyes \
  -applyxfm -init ${outbase}/dwi/t1_to_MUSE.mat \
  -out ${outbase}/dwi/dwi_MUSE_mask_eyes.nii.gz
my_do_cmd mrcalc \
  ${outbase}/dwi/MUSE_mask.nii.gz \
  ${outbase}/dwi/dwi_MUSE_mask_eyes.nii.gz \
  -or \
  ${outbase}/dwi/dwi_MUSE_mask_with_eyes.nii.gz
my_do_cmd $fakeflag mrgrid \
    -voxel $t1_resolution \
    ${outbase}/dwi/MUSE_av_b0.nii.gz \
    regrid \
    ${outbase}/dwi/MUSE_av_b0_regrid.nii.gz
my_do_cmd $fakeflag flirt \
    -ref ${outbase}/dwi/MUSE_av_b0_regrid.nii.gz \
    -in  ${outbase}/anat/t1_noneck.nii.gz \
    -applyxfm -init ${outbase}/dwi/t1_to_MUSE.mat \
    -out ${outbase}/dwi/t12muse.nii.gz  
else echolor green "[INFO] File exists: $fcheck"; fi




# if [ $keep_tmp -eq 1 ]
# then
#   echolor yellow "[INFO] Not deleting temp directory $tmpDir"
# else
#   rm -fR $tmpDir
# fi
