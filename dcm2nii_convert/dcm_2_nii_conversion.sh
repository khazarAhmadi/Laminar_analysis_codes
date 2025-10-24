#!/bin/bash
# little snippet for .dcm to .nii cnoversion using .dcm2niix and folder organization 

IFS=$'\n\t'

# ------------------------------
# Helper function: convert and rename
# ------------------------------
convert_and_rename() {
    local input_dir=$1
    local output_dir=$2
    local label=$3

    dcm2niix -f "%f_%p_%t_%s" -p n -z y -o "$output_dir" "$input_dir"
    # find the newly created NIfTI/JSON and rename using label
    mv "$output_dir"/*.nii.gz "$output_dir/${label}.nii.gz"
    mv "$output_dir"/*.json   "$output_dir/${label}.json"
}

# ------------------------------
# Process session 1 subjects
# ------------------------------
while read -r subj; do
    echo "=== Processing subject: $subj (Session 1) ==="
    cd "$subj" || exit 1

    mkdir -p structural/T1 structural/T2 functional/AP functional/PA

    # --- Structural: MP2RAGE ---
    mp2rage_dirs=(
        "MP2RAGE_FATNAVS_0_75ISO_INV1_0004"
        "MP2RAGE_FATNAVS_0_75ISO_INV2_0005"
        "MP2RAGE_FATNAVS_0_75ISO_UNI_IMAGES_0006"
    )
    mp2rage_labels=("MP2RAGE-INV1" "MP2RAGE-INV2" "MP2RAGE-UNI")
    for i in "${!mp2rage_dirs[@]}"; do
        convert_and_rename "${mp2rage_dirs[$i]}" structural/T1 "${mp2rage_labels[$i]}"
    done
    rm -rf MP2RAGE_*

    # --- Structural: T2 ---
    tse_dirs=(
        "TSE_HIPPOCAMPUS_CORONAL_255V_0007"
        "TSE_HIPPOCAMPUS_CORONAL_235V_0008"
        "TSE_HIPPOCAMPUS_CORONAL_215V_0009"
    )
    for i in "${!tse_dirs[@]}"; do
        convert_and_rename "${tse_dirs[$i]}" structural/T2 "TSE$((i+1))"
    done
    rm -rf TSE_HIPPOCAMPUS_*

    # --- Functional: fMRI (Session 1) ---
    func_dirs_ap=(
        "DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R1_E00_M_0011"
        "DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R2_E00_M_0013"
    )
    func_dirs_pa=(
        "DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R1_E00_M_0010"
        "DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R2_E00_M_0012"
    )

    for i in "${!func_dirs_ap[@]}"; do
        convert_and_rename "${func_dirs_pa[$i]}" functional/PA "Run$((i+1))-PA"
        convert_and_rename "${func_dirs_ap[$i]}" functional/AP "Run$((i+1))-AP"
    done
    rm -rf DZNE_EP3D_*

    cd - >/dev/null || exit 1
done < folders_list.txt

# ------------------------------
# Process session 2 subjects
# ------------------------------
while read -r subj; do
    echo "=== Processing subject: $subj (Session 2) ==="
    cd "$subj" || exit 1

    mkdir -p AP PA

    # R3–R8 runs (6 total)
    for run in {3..8}; do
        convert_and_rename "DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R${run}_E00_M_00$((run*2+1))" PA "Run${run}-PA"
        convert_and_rename "DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R${run}_E00_M_00$((run*2+2))" AP "Run${run}-AP"
    done
    rm -rf DZNE_EP3D_*

    cd - >/dev/null || exit 1
done < Sessions2s.txt

echo "=== All conversions completed successfully ✅ ==="

