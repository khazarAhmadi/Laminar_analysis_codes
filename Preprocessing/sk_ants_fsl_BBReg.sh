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

$(basename $0) ${bold}-f${normal} Anatomical image  ${bold}-m${normal} EPI image ${bold}-s${normal} WM Seg

--------------------------------------------------------------------------------
Input arguments:

    -f: Anatomical image .nii/.nii.gz file

    -m: EPI image .nii/.nii.gz file

    -s: WM Segmentation image .nii/.nii.gz file

    -i: Manual ITK initialisation matrix .txt file (optional)

--------------------------------------------------------------------------------

Example:

$(basename $0) -f home/user/folder/anatomy.nii.gz -m home/user/folder/mean_epi.nii.gz -s home/user/folder/anatomy_wmseg.nii.gz

This command does BBR alignment using FSL FLIRT. Output's transformations in ITK format.

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

    Fixed EPI data        : ${bold} ${ref_data_name}.nii/.nii.gz ${normal}

    Moving EPI data       : ${bold} ${func_data_name}.nii/.nii.gz ${normal}

    WM Seg data           : ${bold} ${wm_seg_name}.nii/.nii.gz ${normal}

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

while getopts "f:m:s:i:" OPT; do
    case $OPT in
    h) #help
        Help
        exit 0
        ;;
    f) # mean epi
        ref_data_path=$OPTARG
        ;;
    m) # mean epi
        func_data_path=$OPTARG
        ;;
    s) # wm_seg
        wm_seg_path=$OPTARG
        ;;
    i) # init_mat
        itk_init_path=$OPTARG
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

if [[ $wm_seg_path =~ \.gz$ ]]; then
    wm_seg=$(basename ${wm_seg_path})
    wm_seg_name=${wm_seg%%.*}
else
    wm_seg=$(basename ${wm_seg_path})
    wm_seg_name=${wm_seg%.*}
fi

################################################################################
#
# REPORT INPUT PARAMETERS
#
################################################################################

reportParameters

################################################################################
#
# DO BBR
#
################################################################################
if [ -z "$itk_init_path" ]; then
    echo "-----> Assuming pre-aligned."
    echo " "
    echo "-----> Starting registration."
    echo " "
    flirt \
        -cost bbr \
        -interp spline \
        -dof 6 \
        -schedule $FSLDIR/etc/flirtsch/bbr.sch \
        -ref $ref_data_path \
        -wmseg $wm_seg_path \
        -in $func_data_path \
        -out $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr.nii.gz \
        -omat $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr.mat &>/dev/null

    # Convert FSL to ITK
    echo "-----> Converting FSL to ITK ... "
    echo ""
    c3d_affine_tool \
        -ref $ref_data_path \
        -src $func_data_path \
        $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr.mat \
        -fsl2ras \
        -oitk $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr_itk.mat

    echo "-----> FSL registration matrix ${func_data_name}_reg2anat_bbr.mat created."
    echo " "
    echo "-----> ITK registration matrix ${func_data_name}_reg2anat_bbr_itk.txt created."
    echo " "
    echo "-----> Check registered file ${func_data_name}_reg2anat_bbr.nii.gz"
    echo " "
else
    itk_init=$(basename ${itk_init_path})
    itk_init_name=${itk_init%.*}
    echo "-----> Converting manual ITK matrix to FSL."
    echo " "
    c3d_affine_tool \
        -ref $ref_data_path \
        -src $func_data_path \
        -itk $itk_init_path \
        -ras2fsl \
        -o $(dirname $itk_init_path)/${itk_init_name}_itk2fsl.mat

    echo "-----> Starting registration."
    echo " "
    flirt \
        -cost bbr \
        -interp spline \
        -dof 6 \
        -schedule $FSLDIR/etc/flirtsch/bbr.sch \
        -ref $ref_data_path \
        -wmseg $wm_seg_path \
        -init $(dirname $itk_init_path)/${itk_init_name}_itk2fsl.mat \
        -in $func_data_path \
        -out $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr.nii.gz \
        -omat $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr.mat &>/dev/null

    # Convert FSL to ITK
    echo "-----> Converting FSL to ITK ... "
    echo ""
    c3d_affine_tool \
        -ref $ref_data_path \
        -src $func_data_path \
        $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr.mat \
        -fsl2ras \
        -oitk $(dirname $func_data_path)/${func_data_name}_reg2anat_bbr_itk.mat

    echo "-----> FSL registration matrix ${func_data_name}_reg2anat_bbr.mat created."
    echo " "
    echo "-----> ITK registration matrix ${func_data_name}_reg2anat_bbr_itk.txt created."
    echo " "
    echo "-----> Check registered file ${func_data_name}_reg2anat_bbr.nii.gz"
    echo " "
fi

end_time=$(date +%s)
nettime=$(expr $end_time0 - $start_time0)
