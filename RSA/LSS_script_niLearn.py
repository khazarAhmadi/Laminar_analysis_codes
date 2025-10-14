import pandas as pd
import os
from nilearn.glm.first_level import FirstLevelModel
from nilearn.image import load_img
from pathlib import Path
import re

# ==== USER INPUTS ====
TR = 2.5  
folders_file = Path("IDs.txt")
subject_dirs = folders_file.read_text().splitlines()

for subj_dir in subject_dirs:
    subj_path = Path(subj_dir)
    lss_dir = subj_path / "trialwise_LSS"
    bold_base_dir = subj_path 
    
    if not lss_dir.exists() or not bold_base_dir.exists():
        print(f"⚠️ Skipping {subj_path.name}: missing trialwise_LSS or bold data directory.")
        continue

    # Get all relevant .tsv files
    tsv_files = sorted(lss_dir.glob("EVent_table*_cleaned_LSS_final_renamed_objID.tsv"))

    for tsv_file in tsv_files:
        # Extract run number from filename, e.g. EVent_table3... -> 3
        match = re.search(r"EVent_table(\d+)_cleaned", tsv_file.name)
        if not match:
            print(f"❌ Could not parse run number from {tsv_file.name}, skipping.")
            continue
        run_num = match.group(1)

        # Define BOLD path using run number
        bold_dir = bold_base_dir 
        bold_file = bold_dir / f"Run{run_num}-withMean.nii.gz"

        if not bold_file.exists():
            print(f"❌ Missing BOLD for {subj_path.name} run{run_num} at {bold_file}, skipping.")
            continue

        # Load fMRI and events
        fmri_img = load_img(bold_file)
        events = pd.read_csv(tsv_file, sep="\t")
        mask_img = load_img(subj_path / "fast_T1_pveseg_cropped_bin.nii.gz")

        # Output directory for beta maps
        output_dir = subj_path / f"LSS_betas/Run{run_num}/navigation"
        output_dir.mkdir(parents=True, exist_ok=True)

        # Extract navigation trials
        nav_trials = events[events["trial_type"] == "navigation"]
        print(f"🔄 {subj_path.name} run{run_num}: {len(nav_trials)} navigation trials")

        # === LSS LOOP ===
        nav_trials = nav_trials.reset_index(drop=True)
        for trial_idx, trial in nav_trials.iterrows():
            trial_id = trial["object_id"]
            trial_onset = trial["onset"]
            trial_duration = trial["duration"]

            # Trial of interest
            trial_of_interest = pd.DataFrame({
                "onset": [trial_onset],
                "duration": [trial_duration],
                "trial_type": ["nav_target"],
                "modulation": [1]
            })

            # Other navigation trials
            other_navs = nav_trials.drop(trial_idx)  # Use original index
            other_navs = pd.DataFrame({
                "onset": other_navs["onset"],
                "duration": other_navs["duration"],
                "trial_type": "nav_other",
                "modulation": 1
            })

            # Other conditions (cue, imagine, feedback, etc.)
            other_events = events[events["trial_type"] != "navigation"]
            nuisance = pd.DataFrame({
                "onset": other_events["onset"],
                "duration": other_events["duration"],
                "trial_type": "nuisance",
                "modulation": 1
            })

            # Combine all into one events DataFrame
            lss_events = pd.concat([trial_of_interest, other_navs, nuisance], ignore_index=True)

            # === FIT GLM ===
            model = FirstLevelModel(
                t_r=TR,
                noise_model='ar1',
                standardize=False,
                hrf_model='glover',
                minimize_memory=True,
                mask_img=mask_img
            )

            try:
                model.fit(fmri_img, events=lss_events)
                beta_map = model.compute_contrast("nav_target", output_type='effect_size')

                # Save beta map
                beta_fname = f"navigation_trial-{trial_idx+1:03}_obj-{trial_id}.nii.gz"
                beta_path = output_dir / beta_fname
                beta_map.to_filename(beta_path)

                print(f"✅ Saved: {beta_path}")
            except Exception as e:
                print(f"❌ GLM failed for {subj_path.name} run{run_num} trial {trial_idx+1} (obj-{trial_id}): {e}")


