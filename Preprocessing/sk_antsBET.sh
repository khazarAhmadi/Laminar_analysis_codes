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

$(basename $0) ${bold}-i${normal} Mean image 

--------------------------------------------------------------------------------
Input arguments:

    -i: Mean EPI image .nii/.nii.gz file

--------------------------------------------------------------------------------

Example:

$(basename $0) -i home/user/folder/epi_mean.nii.gz

This command can create a brainmask for a partial FoV EPI dataset. 
Tested on 7T 3D-EPI.

--------------------------------------------------------------------------------
Script was created by: Sriranga Kashyap (05-2021)
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

    Mean EPI data       : ${bold} ${func_data_name}.nii.gz ${normal}
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

while getopts "i:" OPT; do
    case $OPT in
        h) #help
            Help
            exit 0
        ;;
        i) # mean epi
            func_data_path=$OPTARG
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
if [[ $func_data_path =~ \.gz$ ]]; then  
func_data=$(basename ${func_data_path})
func_data_name=${func_data%%.*}
else 
func_data=$(basename ${func_data_path})
func_data_name=${func_data%.*}
fi


################################################################################
#
# REPORT INPUT PARAMETERS
#
################################################################################

reportParameters

################################################################################
#
# DO MASKING
#
################################################################################
echo "-----> Removing bias-field."
echo " "
${ANTSPATH}/N4BiasFieldCorrection \
-d 3 \
-i $func_data \
-o ${func_data_name}_n4.nii.gz

echo "-----> Getting a rough mask."
echo " "

${ANTSPATH}/ImageMath \
3 \
${func_data_name}_n4_mask.nii.gz \
ThresholdAtMean \
${func_data_name}_n4.nii.gz \
1.5

echo "-----> Running morphological operations."
echo " "
${ANTSPATH}/ImageMath \
3 \
${func_data_name}_n4_mask.nii.gz \
ME \
${func_data_name}_n4_mask.nii.gz \
1

${ANTSPATH}/ImageMath \
3 \
${func_data_name}_n4_mask.nii.gz \
MD \
${func_data_name}_n4_mask.nii.gz \
1

${ANTSPATH}/ImageMath \
3 \
${func_data_name}_n4_mask.nii.gz \
GetLargestComponent \
${func_data_name}_n4_mask.nii.gz

${ANTSPATH}/ImageMath \
3 \
${func_data_name}_n4_mask.nii.gz \
MC \
${func_data_name}_n4_mask.nii.gz \
10

${ANTSPATH}/ImageMath \
3 \
${func_data_name}_n4_mask.nii.gz \
MD \
${func_data_name}_n4_mask.nii.gz \
1

echo "-----> Mask created."
echo " "

end_time=$(date +%s)
nettime=$(expr $end_time0 - $start_time0)