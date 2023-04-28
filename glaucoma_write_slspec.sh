#!/bin/bash

DWI=$1



nSlices=$(mrinfo -size $DWI | awk '{print $3}')
TR=$(jq -r .RepetitionTime ${DWI%.nii.gz}.json);
MB=$(jq -r .MultibandAccelerationFactor ${DWI%.nii.gz}.json);


echolor cyan "[INFO] nSlices   = $nSlices"
echolor cyan "[INFO] TR        = $TR s"
echolor cyan "[INFO] MB        = $MB"


slspec=${DWI%.nii.gz}_slspec.txt
t_mjob=/tmp/slspec_$$.m

echo "addpath('/home/inb/lconcha/fmrilab_software/tools/matlab/toolboxes/GESliceTimingPackage-2.1/');" >> $t_mjob
echo "[ms,tr,shotnumorder] = SliceTiming(${MB},${nSlices},${TR},'Sequential', 'Ascending');" >> $t_mjob
echo "slspec = shotnumorder2slspec(${MB},shotnumorder);" >> $t_mjob
echo "writematrix(slspec,'$slspec','Delimiter',' ');" >> $t_mjob
echo "fprintf(1,'Wrote $slspec \n\n');" >> $t_mjob
echo "exit"  >> $t_mjob

echolor cyan "-------- Start matlab job ----------"
cat $t_mjob
matlab -nodisplay -nosplash -nojvm <$t_mjob
echolor cyan "--------- End matlab job -----------"

cat $slspec
rm $t_mjob