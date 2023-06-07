#!/bin/bash
source `which my_do_cmd`
fakeflag=""


sID=$1


synthstrip=/misc/mansfield/lconcha/containers/synthstrip-singularity
bids_dir=/misc/mansfield/lconcha/exp/glaucoma/bids



# t1=$1
# dwi_HB=$2;   # corrected
# dwi_MUSE=$3; # corrected
# outdir=$4

t1=${bids_dir}/sub-${sID}/anat/sub-${sID}_T1w.nii.gz
dwi_HB=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-hb_dwi_de.mif
dwi_MUSE=${bids_dir}/derivatives/sub-${sID}/dwi/sub-${sID}_acq-muse_dwi_de.mif
outdir=${bids_dir}/derivatives/sub-${sID}/
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
if [ $isOK -eq 0 ]; then echolor red "[ERROR] Cannot continue";exit 2; fi



echo "
T1      : $t1
dwi_HB  : $dwi_HB
outdir  : $outdir
"




t1_resolution=$(mrinfo -spacing $t1 | tr ' ' ',')



atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz
atlas_fa=$FSLDIR/data/standard/FSL_HCP1065_FA_2mm.nii.gz

#mask_eyes=/misc/mansfield/lconcha/exp/glaucoma/eyes_mask_MNI_2mm.nii.gz
mask_eyes=/misc/mansfield/lconcha/exp/glaucoma/MNI152_T1_2mm_eyes_opticNerves_mask.nii.gz


echolor cyan "[INFO] Removing neck"
fcheck=${outdir}/anat/t1_noneck.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  my_do_cmd $fakeflag robustfov -i $t1 -r ${outdir}/anat/t1_noneck.nii.gz
else echolor green "[INFO] File exists: $fcheck"; t1=$fcheck; fi
t1=${outdir}/anat/t1_noneck.nii.gz


echolor cyan "[INFO] Brain mask for T1 via sytnthstrip"
fcheck=${outdir}/anat/t1_brain.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  $synthstrip --no-csf \
    -i $t1 \
    -o ${outdir}/anat/t1_brain.nii.gz \
    -m ${outdir}/anat/t1_mask.nii.gz
else
  echolor green "[INFO] File exists: $fcheck"
fi
t1=${outdir}/anat/t1_brain.nii.gz


echolor cyan "[INFO] Resampling to 2 mm"
fcheck=${outdir}/anat/t1_2mm_brain.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag mrgrid \
  -vox 2 \
  -interp nearest \
  $t1 \
  regrid \
  ${outdir}/anat/t1_2mm_brain.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi


fcheck=${outdir}/anat/sub2atlas_lin.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Running FLIRT to the skull-stripped atlas"
echolor cyan "[INFO] Atlas is: $atlas_t1"
my_do_cmd $fakeflag flirt \
  -ref  $atlas_t1 \
  -in   ${outdir}/anat/t1_2mm_brain.nii.gz \
  -out  ${outdir}/anat/sub2atlas_lin \
  -omat ${outdir}/anat/sub2atlas_lin.mat
else echolor green "[INFO] File exists: $fcheck"; fi
  


fcheck=${outdir}/anat/sub2atlas_nlin_field.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Running FNIRT to the __non-skull-stripped__ atlas"
atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
echolor cyan "[INFO] Atlas is: $atlas_t1"
my_do_cmd $fakeflag fnirt \
  --ref=$atlas_t1 \
  --in=${outdir}/anat/t1_2mm_brain.nii.gz \
  --fout=${outdir}/anat/sub2atlas_nlin_field \
  --iout=${outdir}/anat/sub2atlas_nlin \
  --aff=${outdir}/anat/sub2atlas_lin.mat \
  -v
else echolor green "[INFO] File exists: $fcheck"; fi


fcheck=${outdir}/anat/atlas2sub_nlin_field.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Inverting warp"
my_do_cmd $fakeflag invwarp \
  -w ${outdir}/anat/sub2atlas_nlin_field \
  -o ${outdir}/anat/atlas2sub_nlin_field \
  -r ${outdir}/anat/t1_2mm_brain.nii.gz \
  -v
else echolor green "[INFO] File exists: $fcheck"; fi

fcheck=${outdir}/anat/atlas2sub_mask_eyes.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Putting mask in t1 native space"
my_do_cmd $fakeflag applywarp \
  -i $mask_eyes \
  -o ${outdir}/anat/atlas2sub_mask_eyes \
  -r $t1 \
  -w ${outdir}/anat/atlas2sub_nlin_field \
  --interp=nn \
  -v  
else echolor green "[INFO] File exists: $fcheck"; fi

fcheck=${outdir}/anat/atlas2sub.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
echolor cyan "[INFO] Putting atlas in t1 native space"
atlas_t1=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
echolor cyan "[INFO] Atlas is: $atlas_t1"
my_do_cmd $fakeflag applywarp \
  -i $atlas_t1 \
  -o ${outdir}/anat/atlas2sub \
  -r $t1 \
  -w ${outdir}/anat/atlas2sub_nlin_field \
  --interp=nn \
  -v  
else echolor green "[INFO] File exists: $fcheck"; fi



echolor cyan "[INFO] -------- DTI masking ------------"
fcheck=${outdir}/dwi/HB_av_b900_masked.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  my_do_cmd $fakeflag dwi2mask \
    $dwi_HB ${outdir}/dwi/HB_mask.mif
  dwiextract \
    -shell 800 \
    $dwi_HB - | \
  mrmath -axis 3 - mean - |\
  mrcalc - ${outdir}/dwi/HB_mask.mif -mul \
    ${outdir}/dwi/HB_av_b900_masked.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi


echolor cyan "[INFO] Registering t1 to dwi"
fcheck=${outdir}/dwi/t1_to_HB.nii.gz
  if [ ! -f $fcheck -o $force -eq 1 ]; then
  my_do_cmd $fakeflag flirt \
    -ref ${outdir}/dwi/HB_av_b900_masked.nii.gz \
    -in  ${outdir}/anat/t1_brain.nii.gz \
    -omat ${outdir}/dwi/t1_to_HB.mat
  my_do_cmd $fakeflag mrgrid \
    -voxel $t1_resolution \
    ${outdir}/dwi/HB_av_b900_masked.nii.gz \
    regrid \
    ${outdir}/dwi/HB_av_b900_masked_regrid.nii.gz
  my_do_cmd $fakeflag flirt \
    -ref ${outdir}/dwi/HB_av_b900_masked_regrid.nii.gz \
    -in  ${outdir}/anat/t1_noneck.nii.gz \
    -applyxfm -init ${outdir}/dwi/t1_to_HB.mat \
    -out ${outdir}/dwi/t1_to_HB.nii.gz  
else echolor green "[INFO] File exists: $fcheck"; fi


fcheck=${outdir}/dwi/HB_mask_with_eyes.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd flirt \
  -ref ${outdir}/dwi/HB_av_b900_masked.nii.gz \
  -in ${outdir}/anat/atlas2sub_mask_eyes \
  -applyxfm -init ${outdir}/dwi/t1_to_HB.mat \
  -out ${outdir}/dwi/HB_mask_eyes.nii.gz
my_do_cmd mrcalc \
  ${outdir}/dwi/HB_mask.mif \
  ${outdir}/dwi/HB_mask_eyes.nii.gz \
  -or \
  ${outdir}/dwi/HB_mask_with_eyes.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi





# dwi2tensor -mask ${outdir}/dwi/HB_mask_eyes.nii.gz $dwi_HB - |\
# tensor2metric -fa ${tmpDir}/fa.mif -adc ${tmpDir}/adc.mif -

# mrcalc $(mrcalc ${tmpDir}/fa.mif 0.1 -gt -) $(mrcalc ${tmpDir}/fa.mif 1 -lt -) -and ${tmpDir}/fa_ok.mif
# mrcalc $(mrcalc ${tmpDir}/adc.mif 0.0001 -gt -) $(mrcalc ${tmpDir}/adc.mif 0.01 -lt -) -and ${tmpDir}/adc_ok.mif
# mrcalc ${tmpDir}/*_ok.mif -mul \
#   ${outdir}/dwi/HB_mask_eyes.nii.gz -mul 0 -gt \
#   ${outdir}/dwi/HB_mask.mif  -or \
#   ${outdir}/dwi/HB_mask_with_eyes_clean.nii.gz


echolor cyan "[INFO] ---------- Working on MUSE DWI ----------"

fcheck=${outdir}/dwi/MUSE_av_b0_masked.nii.gz
if [ ! -f $fcheck -o $force -eq 1 ]; then
  dwiextract -bzero $dwi_MUSE - | mrmath -quiet -axis 3 - mean ${outdir}/dwi/MUSE_av_b0.nii.gz
  dwiextract -bzero $dwi_HB   - | mrmath -quiet -axis 3 - mean ${outdir}/dwi/HB_av_b0.nii.gz
  dwi2mask $dwi_MUSE ${outdir}/dwi/MUSE_mask.nii.gz
  mrcalc ${outdir}/dwi/MUSE_av_b0.nii.gz \
    ${outdir}/dwi/MUSE_mask.nii.gz \
    -mul \
    ${outdir}/dwi/MUSE_av_b0_masked.nii.gz
else echolor green "[INFO] File exists: $fcheck"; fi




fcheck=${outdir}/dwi/HB_to_MUSE_av_b0.mat
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag flirt \
  -ref  ${outdir}/dwi/MUSE_av_b0.nii \
  -in   ${outdir}/dwi/HB_av_b0.nii \
  -out  ${outdir}/dwi/HB_to_MUSE_av_b0.nii.gz \
  -omat ${outdir}/dwi/HB_to_MUSE_av_b0.mat
else echolor green "[INFO] File exists: $fcheck"; fi



fcheck=${outdir}/dwi/t12muse.nii.gz 
if [ ! -f $fcheck -o $force -eq 1 ]; then
my_do_cmd $fakeflag convert_xfm \
  -omat ${outdir}/dwi/t1_to_MUSE.mat \
  -concat \
  ${outdir}/dwi/HB_to_MUSE_av_b0.mat \
  ${outdir}/dwi/t1_to_HB.mat
my_do_cmd flirt \
  -ref ${outdir}/dwi/MUSE_av_b0.nii.gz \
  -in  ${outdir}/anat/atlas2sub_mask_eyes \
  -applyxfm -init ${outdir}/dwi/t1_to_MUSE.mat \
  -out ${outdir}/dwi/MUSE_mask_eyes.nii.gz
my_do_cmd mrcalc \
  ${outdir}/dwi/MUSE_mask.nii.gz \
  ${outdir}/dwi/MUSE_mask_eyes.nii.gz \
  -or \
  ${outdir}/dwi/MUSE_mask_with_eyes.nii.gz
my_do_cmd $fakeflag mrgrid \
    -voxel $t1_resolution \
    ${outdir}/dwi/MUSE_av_b0.nii.gz \
    regrid \
    ${outdir}/dwi/MUSE_av_b0_regrid.nii.gz
my_do_cmd $fakeflag flirt \
    -ref ${outdir}/dwi/MUSE_av_b0_regrid.nii.gz \
    -in  ${outdir}/anat/t1_noneck.nii.gz \
    -applyxfm -init ${outdir}/dwi/t1_to_MUSE.mat \
    -out ${outdir}/dwi/t12muse.nii.gz  
else echolor green "[INFO] File exists: $fcheck"; fi




# if [ $keep_tmp -eq 1 ]
# then
#   echolor yellow "[INFO] Not deleting temp directory $tmpDir"
# else
#   rm -fR $tmpDir
# fi
