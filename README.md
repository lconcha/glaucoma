# glaucoma
Functions and scripts for the glaucoma project


* `glaucoma_convert.sh` Uses `dcm2bids` for generation of BIDS data set. Reads file name specifications from `glaucoma_dcm2bids_config.json`
* `glaucoma_preproc.sh` Does DWI preprocessing for Hyperband and MUSE using `dwifslpreproc`, reading all the necessary metadata from the .json files.
* `glaucoma_preproc_with_qsprep.sh` does not work. And I don't like relinquishing control like that, so not using.
* `glaucoma_write_slspec.sh` Writes the slspec file for `eddy` but it is not needed anymore since slice timings are available in the .json files converted using `dcm2bids`.
* `glaucoma_reg_and_mask.sh` creates some masks that include optic nerves. Not finished yet.