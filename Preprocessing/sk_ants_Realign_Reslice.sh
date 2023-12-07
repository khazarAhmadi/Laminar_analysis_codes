#! /bin/bash
################################################################################
#
# PREPARATIONS
#
################################################################################

if [[ ${#ANTSPATH} -le 3 ]]; then
    setPath >&2
fi

ANTS=${ANTSPATH}/antsRegistration

if [[ ! -s ${ANTS} ]]; then
    echo "antsRegistration can't be found. Please (re)define $ANTSPATH in your environment."
    exit
fi

################################################################################
# Simple formatting

bold=$(tput bold)
normal=$(tput sgr0)

################################################################################

function Help() {
    cat <<HELP

Usage:

$(basename $0) ${bold}-r${normal} Reference image ${bold}-u${normal} fun2ref.txt ${bold}-r${normal} path to ref image ${bold} -a${normal} Path to 4D fMRI data ${bold}-n${normal} number of threads

--------------------------------------------------------------------------------
Input arguments:

    -r: Reference Func Image

    -u: func-to-reference_func ITK .mat/.txt file

    -v: func-to-reference_func ITK .nii.gz warp file

    -f: Anatomical Image

    -x: func-to-anatomy ITK .mat/.txt file

    -y: func-to-anatomy ITK .nii.gz warp file

    -i: Use inverse of '-x' file  (only if -x is an anatomy-to-func transform)

    -t: TR in seconds (e.g. 2.0)

    -a: Path to 4D fMRI data (e.g. /path/to/data/fMRI.nii.gz) <- was input to Estimate

    -n: Number of threads (default = '16')

--------------------------------------------------------------------------------

Example:

$(basename $0) -t 2.0 -r /home/user/folder/anatomy.nii.gz -a /home/user/folder/file.nii.gz -x /home/user/folder/func2anat.txt -n 24

This command takes the input data processed using the Estimate script,
reslices the data in a single step.

If -r, -u (optional -v), flags are given, inter-run aligned resliced data are created. 
If -f, -x (optional -y), flags are given, anatomy aligned resliced data are created. 
in addition to default = resliced timeseries in native space.

--------------------------------------------------------------------------------
Script was created by: Sriranga Kashyap (11-2020)
--------------------------------------------------------------------------------
Requires ANTs to be installed and $ANTSPATH defined in your environment.
--------------------------------------------------------------------------------
ANTs can be downloaded here: https://github.com/ANTsX/ANTs
References:
    1) http://www.ncbi.nlm.nih.gov/pubmed/20851191
    2) http://www.frontiersin.org/Journal/10.3389/fninf.2013.00039/abstract
--------------------------------------------------------------------------------

HELP
    exit 1
}

################################################################################

function reportParameters() {
    cat <<REPORTPARAMETERS

--------------------------------------------------------------------------------
    ${bold} Processes Initialised ${normal}
--------------------------------------------------------------------------------
    ANTSPATH is $ANTSPATH

    TR                  : ${bold} $tr ${normal}
    4D fMRI data        : ${bold} ${func_data_name} ${normal}
    Inter-run ITK txn   : ${bold} $inter_txn0 ${normal}
    Inter-run ITK txn   : ${bold} $inter_txn1 ${normal}
    Reference run data  : ${bold} ${runref_data_name} ${normal}
    Reference Anatomy   : ${bold} ${anatomy_data_name} ${normal}
    Final anat ITK txn  : ${bold} $final_txn0 ${normal}
    Final anat ITK txn  : ${bold} $final_txn1 ${normal}
    Invert final txn?   : ${bold} $use_inverse ${normal}
    Number of threads   : ${bold} $n_threads ${normal}
--------------------------------------------------------------------------------

REPORTPARAMETERS
}

################################################################################

if [[ "$1" == "-h" || $# -eq 0 ]]; then
    Help >&2
fi

################################################################################
#
# DEFAULTS
#
################################################################################

interpolation_type=LanczosWindowedSinc
n_threads=30

################################################################################
#
# PARSE INPUT ARGUMENTS
#
################################################################################

while getopts "u:v:x:y:f:r:t:j:a:n:i:l:" OPT; do
    case $OPT in
    h) #help
        Help
        exit 0
        ;;
    u) # transform
        inter_txn0=$OPTARG
        ;;
    v) # transform
        inter_txn1=$OPTARG
        ;;
    x) # transform
        final_txn0=$OPTARG
        ;;
    y) # transform
        final_txn1=$OPTARG
        ;;
    f) # transform
        anatomy_path=$OPTARG
        ;;
    r) # transform
        runref_path=$OPTARG
        ;;
    t) # tr
        tr=$OPTARG
        ;;
    a) # 4D fMRI data path
        func_data_path=$OPTARG
        ;;
    n) # transformation type
        n_threads=$OPTARG
        ;;
    i) # use inverse
        use_inverse=$OPTARG
        ;;
    l) # is non-linear
        is_nonlinear=$OPTARG
        ;;
    \?) # report error
        echo "$HELP" >&2
        exit 1
        ;;
    esac
done

################################################################################
#
# SET NUMBER OF THREADS
#
################################################################################

ORIGINALNUMBEROFTHREADS=${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS}
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$n_threads
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

################################################################################
#
# START PROCESSING FILES
#
################################################################################

start_time=$(date +%s)

if [ -z "$final_txn0" ]; then
    echo "--------------------------------------------------------------------------------"
    echo "++++ Final transform not specified."
fi

if [ -z "$inter_txn0" ]; then
    echo "--------------------------------------------------------------------------------"
    echo "++++ EPI space inter-alignment not specified."
fi

if [ -z "$final_txn1" ]; then
    echo "--------------------------------------------------------------------------------"
    echo "++++ Final linear transforms."
elif [ -z "$inter_txn1" ]; then
    echo "--------------------------------------------------------------------------------"
    echo "++++ No inter-run non-linear transforms."
else
    echo "--------------------------------------------------------------------------------"
    echo "++++ Using non-linear transforms."
fi

# GET INPUTS
func_data=$(basename ${func_data_path})
func_data_name=${func_data%%.*}

if [ -z "$anatomy_path" ]; then
    echo "--------------------------------------------------------------------------------"
    echo "++++ Anatomy path is not specified."
else
    anatomy_data=$(basename ${anatomy_path})
    anatomy_data_name=${anatomy_data%%.*}
fi

if [ -z "$runref_path" ]; then
    echo "--------------------------------------------------------------------------------"
    echo "++++ Run reference is not specified."
else

    runref_data=$(basename ${runref_path})
    runref_data_name=${runref_data%%.*}
fi

################################################################################
# GET NUMBER OF VOLUMES FROM HEADER

n_vols_func=$($ANTSPATH/PrintHeader $(dirname $func_data_path)/${func_data_name}.nii.gz | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1)

################################################################################
#
# REPORT INPUT PARAMETERS
#
################################################################################

reportParameters

################################################################################
# GET TEMPORARY DIRECTORIES

data_split=$(dirname $func_data_path)/${func_data_name}_split
data_mats=$(dirname $func_data_path)/${func_data_name}_mats

echo "-----> Temporary directories were sourced."
echo " "

################################################################################
# CONCATENATE TRANSFORMS
basevol=1000                            # ANTs indexing
nthvol=$(($basevol + $n_vols_func - 1)) # Zero indexing

echo "-----> Starting motion+distortion correction on functional data."
echo " "

if [ ! -f "$(dirname $func_data_path)/${func_data_name}_MoCorr_DistCorr.nii.gz" ]; then

    if [ -z "$runref_path" ]; then
        echo "-----> No inter-session resampling being done."
        echo " "
        TEMP=$(dirname $func_data_path)/${func_data_name}_DistCorr_

        start_time=$(date +%s)
        for volume in $(eval echo "{$basevol..$nthvol}"); do

            echo -ne "--------------------> Processing $volume"\\r

            INPUT=${data_split}/${func_data_name}_${volume}.nii.gz
            OUTPUT=${data_split}/${func_data_name}_${volume}_Warped-to-EPI.nii.gz
            ### Concatenate the following transforms in order
            # 3) Distortion correction (warp)
            # 2) Distortion correction (mat)
            # 1) Motion correction (mat)

            $ANTSPATH/antsApplyTransforms \
                --output-data-type int \
                --dimensionality 3 \
                --interpolation $interpolation_type \
                --reference-image $(dirname $func_data_path)/$(basename ${TEMP})template0.nii.gz \
                --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_01Warp.nii.gz \
                --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_00GenericAffine.mat \
                --transform ${data_mats}/${func_data_name}_${volume}_0GenericAffine.mat \
                --input $INPUT \
                --output $OUTPUT
        done

        $ANTSPATH/ImageMath \
            4 \
            $(dirname $func_data_path)/${func_data_name}_MoCorr_DistCorr_nativeEPISpaceAligned.nii.gz \
            TimeSeriesAssemble \
            $tr \
            0 \
            ${data_split}/${func_data_name}_*_Warped-to-EPI.nii.gz

        echo "-----> Re-assembled motion+distortion corrected functional data in EPI space."
        echo " "
    else
        echo "-----> Inter-session resampling being done."
        echo " "
        TEMP=$(dirname $func_data_path)/${func_data_name}_DistCorr_
        REF=$(dirname $runref_path)/${runref_data_name}.nii.gz

        if [ -z "$inter_txn1" ]; then
            echo "-----> Inter-session resampling being done using linear transform."
            echo " "

            start_time=$(date +%s)
            for volume in $(eval echo "{$basevol..$nthvol}"); do

                echo -ne "--------------------> Processing $volume"\\r

                INPUT=${data_split}/${func_data_name}_${volume}.nii.gz
                OUTPUT=${data_split}/${func_data_name}_${volume}_Warped-to-RefEPI.nii.gz
                # 4) Coregister to ref (mat)
                # 3) Distortion correction (warp)
                # 2) Distortion correction (mat)
                # 1) Motion correction (mat)

                $ANTSPATH/antsApplyTransforms \
                    --output-data-type int \
                    --dimensionality 3 \
                    --interpolation $interpolation_type \
                    --reference-image $REF \
                    --transform $inter_txn0 \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_01Warp.nii.gz \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_00GenericAffine.mat \
                    --transform ${data_mats}/${func_data_name}_${volume}_0GenericAffine.mat \
                    --input $INPUT \
                    --output $OUTPUT
            done
        else
            echo "-----> Inter-session resampling being done using deformable transform."
            echo " "
            start_time=$(date +%s)
            for volume in $(eval echo "{$basevol..$nthvol}"); do

                echo -ne "--------------------> Processing $volume"\\r

                INPUT=${data_split}/${func_data_name}_${volume}.nii.gz
                OUTPUT=${data_split}/${func_data_name}_${volume}_Warped-to-RefEPI.nii.gz
                # 5) Coregister to ref (warp)
                # 4) Coregister to ref (mat)
                # 3) Distortion correction (warp)
                # 2) Distortion correction (mat)
                # 1) Motion correction (mat)

                $ANTSPATH/antsApplyTransforms \
                    --output-data-type int \
                    --dimensionality 3 \
                    --interpolation $interpolation_type \
                    --reference-image $REF \
                    --transform $inter_txn1 \
                    --transform $inter_txn0 \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_01Warp.nii.gz \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_00GenericAffine.mat \
                    --transform ${data_mats}/${func_data_name}_${volume}_0GenericAffine.mat \
                    --input $INPUT \
                    --output $OUTPUT
            done
        fi
        $ANTSPATH/ImageMath \
            4 \
            $(dirname $func_data_path)/${func_data_name}_MoCorr_DistCorr_nativeEPISpace_interSessionAligned.nii.gz \
            TimeSeriesAssemble \
            $tr \
            0 \
            ${data_split}/${func_data_name}_*_Warped-to-RefEPI.nii.gz

        echo "-----> Re-assembled motion+distortion corrected functional data in EPI space."
        echo " "
    fi
fi

if [ -z "$final_txn0" ]; then
    echo "-----> Final ITK transformation not given, so skipping final step."
    echo " "
else
    if [ -z "$use_inverse" ]; then
        echo "-----> Final ITK transformation found, using as is."
        echo " "
        ANAT=$anatomy_path
        if [ -z "$final_txn1" ]; then
            echo "-----> Final ITK transformation found, using as is, linear."
            echo " "
            for volume in $(eval echo "{$basevol..$nthvol}"); do
                echo -ne "--------------------> Processing $volume"\\r
                INPUT=${data_split}/${func_data_name}_${volume}.nii.gz
                OUTPUT=${data_split}/${func_data_name}_${volume}_Warped-to-Anat.nii.gz
                # 4) Coregister to anatomy (mat)
                # 3) Distortion correction (warp)
                # 2) Distortion correction (mat)
                # 1) Motion correction (mat)
                $ANTSPATH/antsApplyTransforms \
                    --output-data-type int \
                    --dimensionality 3 \
                    --interpolation $interpolation_type \
                    --reference-image $ANAT \
                    --transform $final_txn0 \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_01Warp.nii.gz \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_00GenericAffine.mat \
                    --transform ${data_mats}/${func_data_name}_${volume}_0GenericAffine.mat \
                    --input $INPUT \
                    --output $OUTPUT
            done
        else
            echo "-----> Final ITK transformation found, using as is and deformable."
            echo " "
            ANAT=$anatomy_path
            for volume in $(eval echo "{$basevol..$nthvol}"); do
                echo -ne "--------------------> Processing $volume"\\r
                INPUT=${data_split}/${func_data_name}_${volume}.nii.gz
                OUTPUT=${data_split}/${func_data_name}_${volume}_Warped-to-Anat.nii.gz
                # 4) Coregister to anatomy (mat)
                # 3) Distortion correction (warp)
                # 2) Distortion correction (mat)
                # 1) Motion correction (mat)
                $ANTSPATH/antsApplyTransforms \
                    --output-data-type int \
                    --dimensionality 3 \
                    --interpolation $interpolation_type \
                    --reference-image $ANAT \
                    --transform $final_txn1 \
                    --transform $final_txn0 \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_01Warp.nii.gz \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_00GenericAffine.mat \
                    --transform ${data_mats}/${func_data_name}_${volume}_0GenericAffine.mat \
                    --input $INPUT \
                    --output $OUTPUT
            done
        fi
    else
        echo "-----> Final ITK transformation found, using inverse."
        echo " "
        ANAT=$anatomy_path
        if [ -z "$final_txn1" ]; then
            echo "-----> Final ITK transformation found, using inverse, only linear."
            echo " "
            for volume in $(eval echo "{$basevol..$nthvol}"); do
                echo -ne "--------------------> Processing $volume"\\r
                INPUT=${data_split}/${func_data_name}_${volume}.nii.gz
                OUTPUT=${data_split}/${func_data_name}_${volume}_Warped-to-Anat.nii.gz
                # 4) Coregister to anatomy (mat) invert
                # 3) Distortion correction (warp)
                # 2) Distortion correction (mat)
                # 1) Motion correction (mat)
                $ANTSPATH/antsApplyTransforms \
                    --output-data-type int \
                    --dimensionality 3 \
                    --interpolation $interpolation_type \
                    --reference-image $ANAT \
                    --transform [ $final_txn0 , 1] \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_01Warp.nii.gz \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_00GenericAffine.mat \
                    --transform ${data_mats}/${func_data_name}_${volume}_0GenericAffine.mat \
                    --input $INPUT \
                    --output $OUTPUT
            done
        else
            echo "-----> Final ITK transformation found, using inverse, deformable."
            echo " "
            ANAT=$anatomy_path
            for volume in $(eval echo "{$basevol..$nthvol}"); do
                echo -ne "--------------------> Processing $volume"\\r
                INPUT=${data_split}/${func_data_name}_${volume}.nii.gz
                OUTPUT=${data_split}/${func_data_name}_${volume}_Warped-to-Anat.nii.gz
                # 4) Coregister to anatomy (mat) invert
                # 3) Distortion correction (warp)
                # 2) Distortion correction (mat)
                # 1) Motion correction (mat)
                $ANTSPATH/antsApplyTransforms \
                    --output-data-type int \
                    --dimensionality 3 \
                    --interpolation $interpolation_type \
                    --reference-image $ANAT \
                    --transform $final_txn1 \
                    --transform [ $final_txn0 , 1] \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_01Warp.nii.gz \
                    --transform $(dirname $func_data_path)/${func_data_name}_DistCorr_00GenericAffine.mat \
                    --transform ${data_mats}/${func_data_name}_${volume}_0GenericAffine.mat \
                    --input $INPUT \
                    --output $OUTPUT
            done
        fi
    fi
    end_time=$(date +%s)
    nettime=$(expr $end_time0 - $start_time0)
    # echo " "
    # echo "-----> Completed combined resampling of data in $(($nettime0 / 3600))h:$(($nettime0 % 3600 / 60))m:$(($nettime0 % 60))s."
    # echo " "

    $ANTSPATH/ImageMath \
        4 \
        $(dirname $func_data_path)/${func_data_name}_MoCorr_DistCorr_anatomySpaceAligned.nii.gz \
        TimeSeriesAssemble \
        $tr \
        0 \
        ${data_split}/${func_data_name}_*_Warped-to-Anat.nii.gz

    echo "-----> Re-assembled motion+distortion corrected+coregistered functional data in Anatomical Space."
    echo " "

fi
#rm -rf $data_mats
#rm -rf $data_split
