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

$(basename $0) ${bold}-f${normal} Fixed image  ${bold}-m${normal} Moving image 

--------------------------------------------------------------------------------
Input arguments:

    -f: Fixed image .nii/.nii.gz file

    -g: Fixed mask (for using -x )

    -m: Moving image .nii/.nii.gz file

    -n: Moving mask (for using -x )

    -x: use automatic preAlignment

    -i: Initial manual matrix <- manual initialisation

    -s: Do SyN, when distortions need fixing   

--------------------------------------------------------------------------------

Example:

$(basename $0) -f home/user/folder/anatomy.nii.gz -m home/user/folder/mean_epi.nii.gz

This command does a 1x rigid alignment. Typical use-case : between-days inter-run alignment.

Output files are automatically created: 
-> *_antsFineReg_0GenericAffine.mat
-> *_antsFineReg_Warped.nii.gz

For automatic pre-alignment, specify both masks.

--------------------------------------------------------------------------------
Script was created by: Sriranga Kashyap (11-2021)
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

    Fixed EPI data        : ${bold} ${ref_data_name}.nii.gz ${normal}

    Moving EPI data       : ${bold} ${func_data_name}.nii.gz ${normal}

--------------------------------------------------------------------------------

REPORTPARAMETERS
}

################################################################################

if [[ "$1" == "-h" || $# -eq 0 ]]; then
    Help >&2
fi

################################################################################
#
# PARSE INPUT ARGUMENTS
#
################################################################################

while getopts "f:g:m:n:x:i:s:" OPT; do
    case $OPT in
    h) #help
        Help
        exit 0
        ;;
    f) # mean epi
        ref_data_path=$OPTARG
        ;;
    g) # mean epi
        ref_mask_path=$OPTARG
        ;;
    m) # mean epi
        func_data_path=$OPTARG
        ;;
    n) # mean epi
        func_mask_path=$OPTARG
        ;;
    x) # init mat
        use_ai=$OPTARG
        ;;
    i) # init mat
        init_mat_path=$OPTARG
        ;;
    s) # do syn
        do_syn=$OPTARG
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

start_time=$(date +%s)

# GET INPUTS
if [[ $ref_data_path =~ \.gz$ ]]; then
    ref_data=$(basename ${ref_data_path})
    ref_data_name=${ref_data%%.*}
else
    ref_data=$(basename ${ref_data_path})
    ref_data_name=${ref_data%.*}
fi

if [[ $func_data_path =~ \.gz$ ]]; then
    func_data=$(basename ${func_data_path})
    func_data_name=${func_data%%.*}
else
    func_data=$(basename ${func_data_path})
    func_data_name=${func_data%.*}
fi

if [ -z "$ref_mask_path" ]; then
    echo "-----> Reference mask not given."
    echo " "
else
    echo "-----> Reference mask given."
    echo " "
    if [[ $ref_mask_path =~ \.gz$ ]]; then
        ref_mask=$(basename ${ref_mask_path})
        ref_mask_name=${ref_mask%%.*}
    else
        ref_mask=$(basename ${ref_mask_path})
        ref_mask_name=${ref_mask%.*}
    fi
fi

if [ -z "$func_mask_path" ]; then
    echo "-----> Func mask not given."
    echo " "
else
    echo "-----> Func mask given."
    echo " "
    if [[ $func_mask_path =~ \.gz$ ]]; then
        func_mask=$(basename ${func_mask_path})
        func_mask_name=${func_mask%%.*}
    else
        func_mask=$(basename ${func_mask_path})
        func_mask_name=${func_mask%.*}
    fi
fi

################################################################################
#
# REPORT INPUT PARAMETERS
#
################################################################################

reportParameters

################################################################################
#
# DO AI
#
################################################################################
if [ -z "$init_mat_path" ]; then
    if [ -z "$use_ai" ]; then
        if [ -z "$do_syn" ]; then
            echo "-----> Assuming pre-aligned."
            echo " "
            echo "-----> Starting registration."
            echo " "
            $ANTSPATH/antsRegistration \
                --verbose 0 \
                --random-seed 13 \
                --dimensionality 3 \
                --float 1 \
                --collapse-output-transforms 1 \
                --output [ $(dirname $func_data_path)/${func_data_name}_antsFineReg_,$(dirname $func_data_path)/${func_data_name}_antsFineReg_Warped.nii.gz,1 ] \
                --interpolation LanczosWindowedSinc \
                --use-histogram-matching 1 \
                --winsorize-image-intensities [ 0.005,0.995 ] \
                --initial-moving-transform [$ref_data_path,$func_data_path,1] \
                --transform Rigid[ 0.1 ] \
                --metric MI[ $ref_data_path,$func_data_path,1,64,Regular,0.25 ] \
                --convergence [ 100,1e-6,10 ] \
                --shrink-factors 1 \
                --smoothing-sigmas 0vox
        else
            if [[ -z $ref_mask_path && -z $func_mask_path ]]; then
                echo "-----> Need to specify the fixed and moving masks for SyN."
            else
                echo "-----> Assuming pre-aligned."
                echo " "
                echo "-----> Starting registration."
                echo " "
                echo "-----> Using SyN."
                echo " "
                $ANTSPATH/antsRegistration \
                    --verbose 0 \
                    --random-seed 13 \
                    --dimensionality 3 \
                    --float 1 \
                    --collapse-output-transforms 1 \
                    --output [ $(dirname $func_data_path)/${func_data_name}_antsFineReg_,$(dirname $func_data_path)/${func_data_name}_antsFineReg_Warped.nii.gz,1 ] \
                    --interpolation LanczosWindowedSinc \
                    --use-histogram-matching 1 \
                    --masks [$ref_mask_path,$func_mask_path] \
                    --winsorize-image-intensities [ 0.005,0.995 ] \
                    --initial-moving-transform [$ref_data_path,$func_data_path,1] \
                    --transform Rigid[ 0.1 ] \
                    --metric MI[ $ref_data_path,$func_data_path,1,64,Regular,0.25 ] \
                    --convergence [ 100,1e-6,10 ] \
                    --shrink-factors 1 \
                    --smoothing-sigmas 0vox \
                    --transform SyN[ 0.1,3,0 ] \
                    --metric CC[ $ref_data_path,$func_data_path,1,4 ] \
                    --convergence [ 50x20,1e-6,10 ] \
                    --shrink-factors 2x1 \
                    --smoothing-sigmas 2x0vox
            fi
        fi
        echo "-----> Registration matrix ${func_data_name}_antsFineReg_0GenericAffine.mat created."
        echo "-----> Check registered file ${func_data_name}_antsFineReg_Warped.nii.gz"
        echo " "
    else
        if [[ -z $ref_mask_path && -z $func_mask_path ]]; then
            echo "-----> Need to specify the fixed and moving masks."
        else
            echo "-----> Auto pre-aligning."
            echo "-----> Using both fixed and moving masks"
            echo " "
            $ANTSPATH/antsAI \
                -d 3 \
                --random-seed 13 \
                --verbose 0 \
                --masks [$ref_mask_path,$func_mask_path] \
                -m MI[$ref_data_path,$func_data_path,64,Regular,0.25] \
                -t AlignCentersOfMass \
                -o $(dirname $func_data_path)/${func_data_name}_preAlign.mat
        fi

        if [ -z "$do_syn" ]; then
            echo "-----> Starting registration."
            echo " "
            $ANTSPATH/antsRegistration \
                --verbose 0 \
                --random-seed 13 \
                --dimensionality 3 \
                --float 1 \
                --collapse-output-transforms 1 \
                --output [ $(dirname $func_data_path)/${func_data_name}_antsFineReg_,$(dirname $func_data_path)/${func_data_name}_antsFineReg_Warped.nii.gz,1 ] \
                --interpolation LanczosWindowedSinc \
                --use-histogram-matching 1 \
                --winsorize-image-intensities [ 0.005,0.995 ] \
                --initial-moving-transform $(dirname $func_data_path)/${func_data_name}_preAlign.mat \
                --transform Rigid[ 0.1 ] \
                --metric MI[ $ref_data_path,$func_data_path,1,64,Regular,0.25 ] \
                --convergence [ 100,1e-6,10 ] \
                --shrink-factors 1 \
                --smoothing-sigmas 0vox
        else
            if [[ -z $ref_mask_path && -z $func_mask_path ]]; then
                echo "-----> Need to specify the fixed and moving masks for SyN."
            else
                echo "-----> Starting registration."
                echo " "
                echo "-----> Using SyN."
                echo " "
                $ANTSPATH/antsRegistration \
                    --verbose 0 \
                    --random-seed 13 \
                    --dimensionality 3 \
                    --float 1 \
                    --collapse-output-transforms 1 \
                    --output [ $(dirname $func_data_path)/${func_data_name}_antsFineReg_,$(dirname $func_data_path)/${func_data_name}_antsFineReg_Warped.nii.gz,1 ] \
                    --interpolation LanczosWindowedSinc \
                    --use-histogram-matching 1 \
                    --masks [$ref_mask_path,$func_mask_path] \
                    --winsorize-image-intensities [ 0.005,0.995 ] \
                    --initial-moving-transform [$ref_data_path,$func_data_path,1] \
                    --transform Rigid[ 0.1 ] \
                    --metric MI[ $ref_data_path,$func_data_path,1,64,Regular,0.25 ] \
                    --convergence [ 100,1e-6,10 ] \
                    --shrink-factors 1 \
                    --smoothing-sigmas 0vox \
                    --transform SyN[ 0.1,3,0 ] \
                    --metric CC[ $ref_data_path,$func_data_path,1,4 ] \
                    --convergence [ 20,1e-6,10 ] \
                    --shrink-factors 1 \
                    --smoothing-sigmas 0vox
            fi
        fi
        echo "-----> Registration matrix ${func_data_name}_antsFineReg_0GenericAffine.mat created."
        echo "-----> Check registered file ${func_data_name}_antsFineReg_Warped.nii.gz"
        echo " "
    fi
else
    echo "-----> Using manual initialisation matrix."
    echo " "
    if [ -z "$do_syn" ]; then
        echo "-----> Starting registration."
        echo " "
        $ANTSPATH/antsRegistration \
            --verbose 0 \
            --random-seed 13 \
            --dimensionality 3 \
            --float 1 \
            --collapse-output-transforms 1 \
            --output [ $(dirname $func_data_path)/${func_data_name}_antsFineReg_,$(dirname $func_data_path)/${func_data_name}_antsFineReg_Warped.nii.gz,1 ] \
            --interpolation LanczosWindowedSinc \
            --use-histogram-matching 1 \
            --winsorize-image-intensities [ 0.005,0.995 ] \
            --initial-moving-transform $init_mat_path \
            --transform Rigid[ 0.1 ] \
            --metric MI[ $ref_data_path,$func_data_path,1,64,Regular,0.25 ] \
            --convergence [ 100,1e-6,10 ] \
            --shrink-factors 1 \
            --smoothing-sigmas 0vox
    else
        if [[ -z $ref_mask_path && -z $func_mask_path ]]; then
            echo "-----> Need to specify the fixed and moving masks for SyN."
        else
            echo "-----> Starting registration."
            echo " "
            echo "-----> Using SyN."
            echo " "
            $ANTSPATH/antsRegistration \
                --verbose 0 \
                --random-seed 13 \
                --dimensionality 3 \
                --float 1 \
                --collapse-output-transforms 1 \
                --output [ $(dirname $func_data_path)/${func_data_name}_antsFineReg_,$(dirname $func_data_path)/${func_data_name}_antsFineReg_Warped.nii.gz,1 ] \
                --interpolation LanczosWindowedSinc \
                --use-histogram-matching 1 \
                --winsorize-image-intensities [ 0.005,0.995 ] \
                --initial-moving-transform $init_mat_path \
                --transform Rigid[ 0.1 ] \
                --masks [$ref_mask_path,$func_mask_path] \
                --metric MI[ $ref_data_path,$func_data_path,1,64,Regular,0.25 ] \
                --convergence [ 100,1e-6,10 ] \
                --shrink-factors 1 \
                --smoothing-sigmas 0vox \
                --transform SyN[ 0.1,3,0 ] \
                --masks [$ref_mask_path,$func_mask_path] \
                --metric CC[ $ref_data_path,$func_data_path,1,4 ] \
                --convergence [ 20,1e-6,10 ] \
                --shrink-factors 1 \
                --smoothing-sigmas 0vox
        fi
    fi
    echo "-----> Registration matrix ${func_data_name}_antsFineReg_0GenericAffine.mat created."
    echo "-----> Check registered file ${func_data_name}_antsFineReg_Warped.nii.gz"
    echo " "

fi

end_time=$(date +%s)
nettime=$(expr $end_time0 - $start_time0)
