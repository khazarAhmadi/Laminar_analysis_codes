#!/bin/bash
# ------------------------------------------------------------------------
# AFNI + FSL preprocessing pipeline
# Step 1: Remove dummy volumes (first 3) using AFNI 3dTcat
# Step 2: Remove one top and one bottom slice using FSL fslroi
# Dependencies: AFNI, FSL
# ------------------------------------------------------------------------

IFS=$'\n\t'

# ---------------- Functions ----------------

# Remove dummy volumes from all runs in given directory
remove_dummies() {
    local dir=$1
    echo "  Removing dummy volumes in: $dir"
    cd "$dir" || exit 1

    for f in Run*-*.nii.gz; do
        [[ -f "$f" ]] || continue
        out="${f%.nii.gz}-dummyRemoved.nii.gz"
        echo "    -> $f → $out"
        3dTcat -prefix "$out" "${f}[3..$]" >/dev/null
    done
}

# Remove one slice from top and bottom of each run
remove_slices() {
    local dir=$1
    echo "  Removing top/bottom slices in: $dir"
    cd "$dir" || exit 1

    for f in Run*-*-dummyRemoved.nii.gz; do
        [[ -f "$f" ]] || continue
        out="${f%.nii.gz}-sliceRemove.nii.gz"
        echo "    -> $f → $out"
        fslroi "$f" "$out" 0 -1 0 -1 1 38 >/dev/null
    done
}

# Process one subject (for both AP and PA)
process_subject() {
    local subj_dir=$1
    echo "=== Processing subject: $subj_dir ==="
    cd "$subj_dir/functional" || exit 1

    for pe in AP PA; do
        if [[ -d "$pe" ]]; then
            remove_dummies "$pe"
            remove_slices "$pe"
        else
            echo "  Warning: $pe directory not found in $subj_dir"
        fi
    done

    mkdir -p preprocess_output_complete
    cd - >/dev/null
}

# ---------------- Main Loop ----------------

process_list() {
    local listfile=$1
    echo ">>> Processing subjects from: $listfile"
    while read -r subj; do
        [[ -z "$subj" ]] && continue
        process_subject "$subj"
    done < "$listfile"
}

# ---------------- Run for both sessions ----------------
process_list folders_list.txt
process_list Sessions2s.txt

echo "✅ All preprocessing completed successfully."
