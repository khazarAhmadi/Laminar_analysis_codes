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
    echo "ANTS can't be found. Please (re)define $ANTSPATH in your environment."
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

$(basename $0) ${bold}-r${normal} Fixed Image ${bold} -a${normal} Path to 4D fMRI data ${bold} -t${normal} Path to transformations file

--------------------------------------------------------------------------------
Input arguments:

    -r: Reference image (Specify as /path/to/data/fixed.nii.gz)

    -a: Path to 4D fMRI data (required. Specify as /path/to/data/fMRI.nii.gz)

    -t: transforms file (Specify as /path/to/data/txns.tar.gz)

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Script was created by: Sriranga Kashyap (10-2021)
--------------------------------------------------------------------------------
Requires ANTs to be installed and $ANTSPATH defined in your environment.
--------------------------------------------------------------------------------
ANTs can be downloaded here: https://github.com/ANTsX/ANTs
References to cite:
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

    Reference Image     : ${bold} ${fixed_data_name}.nii.gz ${normal}
    4D fMRI data        : ${bold} ${func_data_name}.nii.gz ${normal}
    Transformations     : ${bold} ${txn_data_name}.tar.gz ${normal}
--------------------------------------------------------------------------------

REPORTPARAMETERS
}

################################################################################

if [[ "$1" == "-h" || $# -eq 0 ]]; then
    Help >&2
fi

while getopts "r:a:t:" OPT; do
    case $OPT in
    h) #help
        Help
        exit 0
        ;;
    r) # fixed data path
        fixed_data_path=$OPTARG
        ;;
    a) # 4D fMRI data path
        func_data_path=$OPTARG
        ;;
    t) # staged processing
        txn_data_path=$OPTARG
        ;;
    \?) # report error
        echo "$HELP" >&2
        exit 1
        ;;
    esac
done

start_time=$(date +%s)

fixed_data=$(basename ${fixed_data_path})
fixed_data_name=${fixed_data%%.*}

func_data=$(basename ${func_data_path})
func_data_name=${func_data%%.*}

txn_data=$(basename ${txn_data_path})
txn_data_name=${txn_data%%.*}

reportParameters

#data_prefix=sub${subject_id}_${modality}_run${run_number}
data_split=$(dirname $func_data_path)/${func_data_name}_split
data_mats=$(dirname $func_data_path)/${func_data_name}_mats

if [ -f "${data_split}/${func_data_name}_${nthvol}_0GenericAffine.mat" ]; then
    echo "-----> Transformations folder found."
else
    mkdir $data_mats
    tar -xf $txn_data_path -C $(dirname $txn_data_path)
fi

# GET NUMBER OF VOLUMES FROM HEADER
n_vols_func=$($ANTSPATH/PrintHeader $(dirname $func_data_path)/${func_data_name}.nii.gz | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1)

# DISASSEMBLE 4D FUNCTIONAL DATA
basevol=1000                            # ANTs indexing
nthvol=$(($basevol + $n_vols_func - 1)) # Zero indexing

if [ -f "${data_split}/${func_data_name}_${nthvol}.nii.gz" ]; then
    echo "-----> Disassembled timeseries data exists."
else
    echo "-----> Disassembling timeseries data."
    mkdir $data_split

    $ANTSPATH/ImageMath \
        4 \
        ${data_split}/${func_data_name}_.nii.gz \
        TimeSeriesDisassemble \
        $(dirname $func_data_path)/${func_data_name}.nii.gz
fi
echo "-----> 4D data was disassembled into its ${bold} $n_vols_func ${normal} constituent volumes."
echo " "

# START MOTION COMPENSATION ON FUNCTIONAL DATA

basevol=1000 # ANTs indexing

nthvol=$(($basevol + $n_vols_func - 1)) # Zero indexing

for volume in $(eval echo "{$basevol..$nthvol}"); do

    FIXED=$(dirname $fixed_data_path)/${fixed_data_name}.nii.gz
    MOVING=${data_split}/${func_data_name}_${volume}
    TXN=${data_mats}/${func_data_name}_${volume}

    $ANTSPATH/ConvertTransformFile 3 \
        ${TXN}_0GenericAffine.mat \
        ${TXN}_ants2itk.mat \
        --hm \
        --ras

    c3d_affine_tool \
        -ref $FIXED \
        -src $MOVING \
        ${TXN}_ants2itk.mat \
        -ras2fsl \
        -o ${TXN}_itk2fsl.mat

done

echo "-----> Compiling motion parameters file in mm and deg."
echo " "

for volume in $(eval echo "{$basevol..$nthvol}"); do

    matrix=${data_mats}/${func_data_name}_${volume}_itk2fsl.mat
    # Use 'avscale' to create file containing Translations (in mm) and Rotations (in deg)
    mm=$(${FSLDIR}/bin/avscale --allparams $matrix $FIXED | grep "Translations" | awk '{print $5 " " $6 " " $7}')
    mmx=$(echo $mm | cut -d " " -f 1)
    mmy=$(echo $mm | cut -d " " -f 2)
    mmz=$(echo $mm | cut -d " " -f 3)
    radians=$(${FSLDIR}/bin/avscale --allparams $matrix $FIXED | grep "Rotation Angles" | awk '{print $6 " " $7 " " $8}')
    radx=$(echo $radians | cut -d " " -f 1)
    degx=$(echo "$radx * (180 / 3.14159)" | sed 's/[eE]+\?/*10^/g' | bc -l)
    rady=$(echo $radians | cut -d " " -f 2)
    degy=$(echo "$rady * (180 / 3.14159)" | sed 's/[eE]+\?/*10^/g' | bc -l)
    radz=$(echo $radians | cut -d " " -f 3)
    degz=$(echo "$radz * (180 / 3.14159)" | sed 's/[eE]+\?/*10^/g' | bc -l)
    # The "%.6f" formatting specifier allows the numeric value to be as wide as it needs to be to accomodate the number
    # Then we mandate (include) a single space as a delimiter between values.
    echo $(printf "%.6f" $mmx) $(printf "%.6f" $mmy) $(printf "%.6f" $mmz) $(printf "%.6f" $degx) $(printf "%.6f" $degy) $(printf "%.6f" $degz) >>$(dirname $func_data_path)/${func_data_name}_MoCorr.params

    # Absolute RMS
    if [[ $volume -eq $nthvol ]]; then
        matrix1=${data_mats}/${func_data_name}_1000_itk2fsl.mat
        matrix2=${data_mats}/${func_data_name}_${volume}_itk2fsl.mat
        ${FSLDIR}/bin/rmsdiff $matrix1 $matrix2 $FIXED >>$(dirname $func_data_path)/${func_data_name}_MoCorr.rmsabs
    else
        matrix1=${data_mats}/${func_data_name}_1000_itk2fsl.mat
        matrix2=${data_mats}/${func_data_name}_$((${volume} + 1))_itk2fsl.mat
        ${FSLDIR}/bin/rmsdiff $matrix1 $matrix2 $FIXED >>$(dirname $func_data_path)/${func_data_name}_MoCorr.rmsabs
    fi
    # Relative RMS
    if [[ $volume -eq $basevol ]]; then
        matrix1=${data_mats}/${func_data_name}_${volume}_itk2fsl.mat
        matrix2=${data_mats}/${func_data_name}_${volume}_itk2fsl.mat
        ${FSLDIR}/bin/rmsdiff $matrix1 $matrix2 $FIXED >>$(dirname $func_data_path)/${func_data_name}_MoCorr.rmsrel
    else
        matrix1=${data_mats}/${func_data_name}_$((${volume} - 1))_itk2fsl.mat
        matrix2=${data_mats}/${func_data_name}_${volume}_itk2fsl.mat
        ${FSLDIR}/bin/rmsdiff $matrix1 $matrix2 $FIXED >>$(dirname $func_data_path)/${func_data_name}_MoCorr.rmsrel
    fi
done

echo "-----> Generating plots."
echo " "

${FSLDIR}/bin/fsl_tsplot -i $(dirname $func_data_path)/${func_data_name}_MoCorr.params -t 'Translations (mm)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o $(dirname $func_data_path)/${func_data_name}_MoCorr_translations.png
${FSLDIR}/bin/fsl_tsplot -i $(dirname $func_data_path)/${func_data_name}_MoCorr.params -t 'Rotations (deg)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o $(dirname $func_data_path)/${func_data_name}_MoCorr_rotations.png
${FSLDIR}/bin/fsl_tsplot -i $(dirname $func_data_path)/${func_data_name}_MoCorr.rmsabs,$(dirname $func_data_path)/${func_data_name}_MoCorr.rmsrel, -t 'Mean Displacements (mm)' -u 1 -a absolute,relative -w 640 -h 144 -o $(dirname $func_data_path)/${func_data_name}_MoCorr_rms.png
