import os
import numpy as np
import nibabel as nib
from scipy.stats import pearsonr
from nilearn.masking import apply_mask
import matplotlib.pyplot as plt
from collections import defaultdict
import csv
import pandas as pd

# ---------- CONFIG ----------
data_root = '.'  # Assuming script is run from /media/elements
subject_list_file = 'IDs.txt'   # Text file listing subjects 
roi_names = ['ca1_merged', 'ca2_merged', 'ca3_merged', 'ca4_merged', 'DG_merged', 'sub_merged',]  # Names of ROIs (per subject)

# ----------------------------

def get_subject_list(id_file):
    with open(id_file, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def parse_obj_id(filename):
    for part in filename.split('_'):
        if part.startswith('obj-'):
            return int(part.split('-')[1].split('.')[0])
    return None

def get_available_run_pairs(subject_path):
    run_base = os.path.join(subject_path, 'LSS_betas')
    if not os.path.isdir(run_base):
        return []

    run_dirs = [
        int(name.replace('Run', ''))
        for name in os.listdir(run_base)
        if name.startswith('Run') and os.path.isdir(os.path.join(run_base, name))
    ]
    run_dirs.sort()
    run_pairs = []
    for i in range(0, len(run_dirs) - 1, 2):
        run1, run2 = run_dirs[i], run_dirs[i + 1]
        if run2 == run1 + 1:
            run_pairs.append((run1, run2))
    return run_pairs

def load_and_group_betas(beta_dir, mask_img):
    beta_files = sorted(f for f in os.listdir(beta_dir) if f.endswith('.nii.gz'))
    obj_dict = defaultdict(list)
    for fname in beta_files:
        obj_id = parse_obj_id(fname)
        fpath = os.path.join(beta_dir, fname)
        beta_img = nib.load(fpath)
        masked_data = apply_mask(beta_img, mask_img)
        obj_dict[obj_id].append(masked_data)

    for obj_id, trials in obj_dict.items():
        if len(trials) != 3:
            print(f"[WARNING] {os.path.basename(beta_dir)}: object {obj_id} has {len(trials)} trials (expected 3)")

    return obj_dict

def compute_rsm(obj_patterns1, obj_patterns2):
    common_objs = sorted(set(obj_patterns1.keys()) & set(obj_patterns2.keys()))
    n = len(common_objs)
    rsm = np.zeros((n, n))
    for i, obj_i in enumerate(common_objs):
        for j, obj_j in enumerate(common_objs):
            r, _ = pearsonr(obj_patterns1[obj_i], obj_patterns2[obj_j])
            rsm[i, j] = r
    return rsm, common_objs

def plot_rsm(rsm, object_ids, subject, roi, run1, run2, outdir):
    plt.figure(figsize=(6, 5))
    plt.imshow(rsm, vmin=-1, vmax=1, cmap='coolwarm')
    plt.colorbar(label='Pearson r')
    plt.xticks(ticks=np.arange(len(object_ids)), labels=object_ids, rotation=45)
    plt.yticks(ticks=np.arange(len(object_ids)), labels=object_ids)
    plt.title(f"{subject} - {roi} - Run {run1} vs {run2}")
    plt.tight_layout()
    fname = f"{subject}_{roi}_Run{run1}vs{run2}_rsm.png"
    fpath = os.path.join(outdir, fname)
    plt.savefig(fpath)
    plt.close()
    print(f"[INFO] Saved RSM heatmap: {fpath}")

def compute_match_mismatch(rsm):
    diag = np.diag(rsm)
    off_diag = rsm[~np.eye(rsm.shape[0], dtype=bool)]
    match_mean = np.mean(diag)
    mismatch_mean = np.mean(off_diag)
    return match_mean, mismatch_mean

# ---------- MAIN SCRIPT ----------
subjects = get_subject_list(subject_list_file)
all_results = []  # ✅ Collect all results here

for subject in subjects:
    subject_path = os.path.join(data_root, subject)
    print(f"\n[PROCESSING] Subject {subject}")
    run_pairs = get_available_run_pairs(subject_path)

    if not run_pairs:
        print(f"[WARNING] No valid run pairs found for {subject}. Skipping.")
        continue

    # Create output directory inside subject folder
    subject_output_dir = os.path.join(subject_path, 'rsa_outputs')
    os.makedirs(subject_output_dir, exist_ok=True)

    for roi_name in roi_names:
        roi_path = os.path.join(subject_path, 'masks', f'{roi_name}.nii.gz')
        if not os.path.exists(roi_path):
            print(f"[WARNING] ROI mask not found: {roi_path}. Skipping {roi_name}.")
            continue

        roi_img = nib.load(roi_path)

        for run1, run2 in run_pairs:
            beta_dir1 = os.path.join(subject_path, f"LSS_betas/Run{run1}/navigation")
            beta_dir2 = os.path.join(subject_path, f"LSS_betas/Run{run2}/navigation")

            if not os.path.isdir(beta_dir1) or not os.path.isdir(beta_dir2):
                print(f"[SKIP] {subject} Run {run1}-{run2}: missing beta directories.")
                continue

            # Load and average betas per object
            obj_betas1 = load_and_group_betas(beta_dir1, roi_img)
            obj_betas2 = load_and_group_betas(beta_dir2, roi_img)

            obj_patterns1 = {obj: np.mean(betas, axis=0) for obj, betas in obj_betas1.items() if len(betas) == 3}
            obj_patterns2 = {obj: np.mean(betas, axis=0) for obj, betas in obj_betas2.items() if len(betas) == 3}

            print(f"[DEBUG] {subject} Run{run1}: {len(obj_patterns1)} objects | Run{run2}: {len(obj_patterns2)} objects")

            rsm, common_obj_ids = compute_rsm(obj_patterns1, obj_patterns2)

            if len(common_obj_ids) != 6:
                print(f"[WARNING] {subject}, {roi_name}, Run {run1}-{run2} has {len(common_obj_ids)} common objects (expected 6).")

            print(f"[INFO] Subject {subject}, ROI {roi_name}, Run {run1}-{run2} → Common objects: {common_obj_ids}")

            # Save RSM data
            npz_path = os.path.join(subject_output_dir, f"{subject}_rsa_{roi_name}_run{run1}vs{run2}.npz")
            np.savez(npz_path, rsm=rsm, object_ids=common_obj_ids)
            print(f"[INFO] Saved RSM data: {npz_path}")

            # Plot RSM
            plot_rsm(rsm, common_obj_ids, subject, roi_name, run1, run2, subject_output_dir)

            # Match vs mismatch similarity
            match_mean, mismatch_mean = compute_match_mismatch(rsm)
            print(f"[RESULT] Match similarity: {match_mean:.3f}, Mismatch similarity: {mismatch_mean:.3f}")
            all_results.append({
    		'subject': subject,
    		'roi': roi_name,
    		'run_pair': f'{run1}-{run2}',
    		'match_similarity': match_mean,
    		'mismatch_similarity': mismatch_mean
	    })
df = pd.DataFrame(all_results)
df.to_csv('rsa_summary_results.csv', index=False)
print("[INFO] Saved summary results to rsa_summary_results.csv")

