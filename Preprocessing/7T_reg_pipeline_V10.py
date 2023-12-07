#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct  4 10:05:31 2021

@author: Carlos A. Gomes

Ants scripts written and pipeline developed by Sri Kashyap 

"""
import os, shutil, glob, psutil, copy, re, json, collections.abc

import numpy as np, pandas as pd
from subprocess import Popen,PIPE
import matlab.engine
import multiprocessing as mp
from operator import itemgetter

############## CHANGE THE FOLLOWING VARIABLES ##################################

work_dir = '/media/sf_G_80tb/7T/DATA/Subs789/trimmed/07/' # working directory - everything will be saved here
dir_m_scripts = '/media/sf_G_80tb/7T/scripts' # the location of the matlab MPRAGEise.m script

# Place the reference runs for each day as the first run in the dictionary for that day
# e.g., if run3 is the reference run of day2 then that run should be the first, 
# if run4 of day2 is the reference run for that day, then move run4 to the top
# so that it is above run3
func_data = {\
             # 'day1': {'run1': {'func': '/media/sf_G_80tb/7T/DATA/Khazar_3runs/Run1-AP-M_POCS_dummyremoved_SliceRemoved.nii.gz',
             #                   'opp': '/media/sf_G_80tb/7T/DATA/Khazar_3runs/Run1-PA-M_POCS_dummyremoved_SliceRemoved.nii.gz'},
             #          'run2': {'func': '/media/sf_G_80tb/7T/DATA/Khazar_3runs/Run2-AP-M_POCS_dummyremoved_SliceRemoved.nii.gz',
             #                   'opp': '/media/sf_G_80tb/7T/DATA/Khazar_3runs/Run2-PA-M_POCS_dummyremoved_SliceRemoved.nii.gz'},
             #          'run3': {'func': '/media/sf_G_80tb/7T/DATA/Khazar_3runs/Run3-AP-M_POCS_dummyremoved_SliceRemoved.nii.gz',
             #                   'opp': '/media/sf_G_80tb/7T/DATA/Khazar_3runs/Run3-PA-M_POCS_dummyremoved_SliceRemoved.nii.gz'}}
                     
              'day1': {'run1': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run1-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run1-PA-dummyRemoved-sliceRemove.nii.gz'},
                      'run2': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run2-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run2-PA-dummyRemoved-sliceRemove.nii.gz'}},
                     
              'day2': {'run3': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run3-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run3-PA-dummyRemoved-sliceRemove.nii.gz'},
                        'run4': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run4-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run4-PA-dummyRemoved-sliceRemove.nii.gz'},
                        'run5': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run5-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run5-PA-dummyRemoved-sliceRemove.nii.gz'},
                        'run6': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run6-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run6-PA-dummyRemoved-sliceRemove.nii.gz'},
                        'run7': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run7-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run7-PA-dummyRemoved-sliceRemove.nii.gz'},
                        'run8': {'func': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run8-AP-dummyRemoved-sliceRemove.nii.gz',
                                'opp': '/media/sf_G_80tb/7T/DATA/Subs789/07/Run8-PA-dummyRemoved-sliceRemove.nii.gz'}},
                
            }


UNI_file = '/media/sf_G_80tb/7T/DATA/Subs789/07/MP2RAGE-UNI.nii.gz'
INV2_file = '/media/sf_G_80tb/7T/DATA/Subs789/07/MP2RAGE-INV2.nii.gz'
  
# 'ref' is your master ref run. If you have acquired data over several days,
# add other reference runs to 'other_ref'
ref_dayrun = {'ref': {'day1': {'day1': 'run1'}}, 
              'other_ref': {'day1': {'day1': 'run1'}}}
# ref_dayrun = {'ref': {'day1':'run1'}}


trim = 5 # choose 0 or False for no trimming - this is for testing purposes

TR = 2.5

# these options are currently not used (work in progress)
custom_files = {\
                'day2': {'run3': {'init': '/home/f02/7T/new_P3/savereg_day2-to-day1.txt'}},
                }

custom_mask = '' # if automatic mask is poor, add a manual mask here

custom_reg = '' # manual registration file if choosing method=='customreg'

method = 'bbrreg' # choose between "finereg", "customreg", "bbrreg". customreg requires a manual registration file (custom_reg)

###############################################################################
####################### PROCESSING STARTS HERE ################################
###############################################################################

if not os.path.exists(work_dir): os.makedirs(work_dir)

cmd_f = os.path.join(work_dir, 'CMD.txt')
var_json = os.path.join(work_dir, 'VARS.json')

nthreads = psutil.cpu_count()

dayref = list(ref_dayrun['ref'].keys())[0]
runref = list(ref_dayrun['ref'].values())[0]

###############################################################################
# helper functions
def split_filename(path):
    exts = ['\.nii.gz$', '\.nii$', '\.mat$', '\.txt$']
    exp = '({})'.format('|'.join(exts))
    [base, nameext] = os.path.split(path)
    [filename, ext, _] = re.split(exp, nameext)
    return base, filename, ext

def flatten(l):
    for x in l:
        if hasattr(x, '__iter__') and not isinstance(x, str):
            for y in flatten(x):
                yield y
        else:
            yield x
            
def update(d, u):
    for k, v in u.items():
        if isinstance(v, collections.abc.Mapping):
            d[k] = update(d.get(k, {}), v)
        else:
            d[k] = v
    return d

###############################################################################

def get_file_names(func=func_data, uni=UNI_file, inv2=INV2_file, work_dir=work_dir):
    
    dat = {}
    for day,runi in func_data.items():
        dat[day] = {}
        for run,d in runi.items():
            dat[day][run] = {}
            for im,file in d.items():
                [base,filename,ext] = split_filename(file)     
                new_file = os.path.join(work_dir, filename+ext)
                if not os.path.isfile(new_file):
                    p = '# Copying {old} into {new}\n\n'.format(old=file,new=new_file)
                    print(p)
                    new_file = shutil.copyfile(file, new_file)
                    with open(cmd_f, 'a+') as f:
                        f.write(p)
                dat[day][run][im] = new_file
    
    
    [base,uni_filename,uni_ext] = split_filename(uni) 
    uni_file = os.path.join(work_dir, uni_filename+uni_ext)
    if not os.path.isfile(uni_file):
        uni_file = shutil.copyfile(uni, uni_file) 
        p = '# Copying {old} into {new}\n\n'.format(old=uni,new=uni_file)
        print(p)
        with open(cmd_f, 'a+') as f:
            f.write(p)
    
    [base,inv2_filename,inv2_ext] = split_filename(inv2) 
    inv2_file = os.path.join(work_dir, inv2_filename+inv2_ext)
    if not os.path.isfile(inv2_file):
        inv2_file = shutil.copyfile(inv2, inv2_file) 
        p = '# Copying {old} into {new}\n\n'.format(old=inv2,new=inv2_file)
        print(p)
        with open(cmd_f, 'a+') as f:
            f.write(p)


    return dat, uni_file, inv2_file

func_data, UNI_file, INV2_file = get_file_names(func_data, UNI_file, INV2_file, work_dir=work_dir)

def trim_data(func_data, work_dir=work_dir, vols=20):
    
    for day,runi in func_data.items():
        for run,d in runi.items():
            for im,file in d.items():
                if im=='func':
                    [base,func_filename,func_ext] = split_filename(file)     
                    out_file = os.path.join(base, '{func_filename}_{vols}vols{ext}'.format(func_filename=func_filename, 
                                                                                           vols=vols,
                                                                                           ext=func_ext))
                    
                    if not os.path.isfile(out_file):                
                        cmd = 'fslroi {func_file} {out_file} 0 {vols}'.format(func_file=file, out_file=out_file, vols=vols)
                        print('\nTrimming {}...\n\n'.format(out_file))
                        res_trim = Popen(cmd, shell=True, stdout=PIPE, cwd=work_dir).stdout.read()
                        print(res_trim)
                        
                        with open(cmd_f, 'a+') as f:
                            f.write(cmd)
                            f.write('\r\r')
                    
                    func_data[day][run][im] = out_file
            
    return func_data

if trim: func_data = trim_data(func_data, vols=trim)
    

def antsRealignEstimate(func_data, fixed_im=None, fixed_mask=None, s=0, TR=TR, nthreads=nthreads,work_dir=work_dir):
    
    data = copy.deepcopy(func_data)
    for day,runi in data.items():
        for run,d in runi.items():
            
            [_,ffunc,_] = split_filename(d['func'])
            try:
                if s:
                    fixed = os.path.join(work_dir, '{}*_fixed.nii.gz'.format(ffunc))
                    fixedmask = os.path.join(work_dir,'{}*fixedMask.nii.gz'.format(ffunc))
                    fixedmask = glob.glob(fixedmask)[0]
                    fixed = glob.glob(fixed)[0]
                else:
                    temp0 = os.path.join(work_dir, '{}*DistCorr_template0.nii.gz'.format(ffunc))
                    aff_mat = os.path.join(work_dir, '{}*DistCorr_00GenericAffine.mat'.format(ffunc))
                    temp0 = glob.glob(temp0)[0]
                    aff_mat = glob.glob(aff_mat)[0]
            except IndexError:
                addflags = ''
                if not s:
                    if fixed_im and fixed_mask:
                        n4_avg_func = fixed_im
                        mask_avg_func = fixed_mask
                    else:
                        n4_avg_func = d['fixed_im']
                        mask_avg_func = d['fixed_mask']
                    addflags = '-f {func_n4} -x {func_mask}'.format(func_n4=n4_avg_func,
                                                                    func_mask=mask_avg_func,)

                sp ='' if not s else '-s 1' 
                cmd = 'sk_ants_Realign_Estimate.sh -n {nthreads} -t {TR} -a {func} -b {opp} {addflags} {s}'.format(TR=TR,
                                                                                                                   func=d['func'],
                                                                                                                   nthreads=nthreads,
                                                                                                                   opp=d['opp'],
                                                                                                                   addflags=addflags,
                                                                                                                   s=sp)
                print('\nRunning:\n',cmd,'\n')
                res = Popen(cmd, shell=True, stdout=PIPE, cwd=work_dir).stdout.read()
                print(res)
                with open(cmd_f, 'a+') as f:
                    f.write(cmd)
                    f.write('\r\r')
                
            print(data)
            if s:
                data[day][run]['fixed_mask'] = glob.glob(fixedmask)[0]           
                data[day][run]['fixed_im'] = glob.glob(fixed)[0]
            else:
                data[day][run]['temp0'] = glob.glob(temp0)[0]
                data[day][run]['aff_mat'] = glob.glob(aff_mat)[0]
    
    return data

func_data_DistCor = {}

for d in ref_dayrun.values():
    
    # process reference run of each session first
    curday = list(d.keys())[0] #current day
    drref = list(d.values())[0] #which day/run will be the reference run
    dref = list(drref.keys())[0] #the reference day for current day
    rref = list(drref.values())[0] #the reference day for current day
    rdat = {dref: {rref: func_data[dref][rref]}}
    temp = antsRealignEstimate(rdat, s=1)
    func_data_DistCor = update(func_data_DistCor, temp)
    
    # get fixed image and mask from reference run of each session
    fixed_im = func_data_DistCor[dref][rref]['fixed_im'] 
    fixed_mask = func_data_DistCor[dref][rref]['fixed_mask']  
    
    # process reference run fully by omitting s and providing fixed_im and fixed_mask
    temp = antsRealignEstimate(rdat,fixed_im=fixed_im, fixed_mask=fixed_mask, s=0)
    func_data_DistCor = update(func_data_DistCor, temp)
    
    # use fixed and mask from reference run to process additional within-session runs
    other_data = {}
    [update(other_data, {dref: {r: func_data[dref][r]}}) for r in func_data[dref].keys() if r!=rref]
    temp = antsRealignEstimate(other_data, fixed_im=fixed_im, fixed_mask=fixed_mask, s=0)
    func_data_DistCor = update(func_data_DistCor, temp)


# If multiple runs, perform inter-run alignement
def InterRunReg(func_data, ref_data, autoalign=1, init=None, use_syn=False, work_dir=work_dir):
    
    data = copy.deepcopy(func_data)
    
    for day,runi in data.items():
        for run,d in runi.items():
          
            
            [_,filename,_] = split_filename(d['func']) 
            affine_mat = os.path.join(work_dir,'{}*antsFineReg*GenericAffine.mat'.format(filename))
            warped_im = os.path.join(work_dir,'{}*antsFineReg_Warped.nii.gz'.format(filename))
            im_1warp = os.path.join(work_dir,'{}*antsFineReg_1Warp.nii.gz'.format(filename))
            
            try:
                affine_mat = glob.glob(affine_mat)[0]
                warped_im = glob.glob(warped_im)[0]
                im_1warp = glob.glob(im_1warp)[0]
                if init:      
                    if not os.path.isfile(init):
                        return print('File {} not found!'.format(init))
                    # else:
                        # check if init file has changed
                        # with open(init) as f1, open('init_interrun.txt') as f2:
                        #     diff = difflib.ndiff
                        
                    # raise IndexError
                
            except IndexError:
                    # use initialisation mat from itksnap    
                    if init:
                        init = os.abspath('init_interrun.txt')
                        addflags = '-i {}'.format(init)

                    # else if using auto-prealign, make sure you add a mask
                    elif autoalign:
                        addflags = '-g {mask_ref} -n {mask_mov} -x 1'.format(mask_ref=ref_data['fixed_mask'],
                                                                             mask_mov=mov_data[day][run]['fixed_mask'])
  
                    syn='' if not use_syn else '-s 1'                       
                    cmd = 'sk_antsFineReg.sh -f {temp_ref} -m {temp_mov} {syn} {addflags}'.format(temp_ref=ref_data['temp0'],
                                                                                                     temp_mov=data[day][run]['temp0'],
                                                                                                     syn=syn,
                                                                                                     addflags=addflags)
                    print('\nRunning:\n',cmd,'\n')
                    res = Popen(cmd, shell=True, stdout=PIPE, cwd=work_dir).stdout.read()
                    print(res)
                    
                    with open(cmd_f, 'a+') as f:
                        f.write(cmd)
                        f.write('\r\r')

            func_data[day][run]['interrun_mat'] = glob.glob(affine_mat)[0]
            func_data[day][run]['interrun_warp'] = glob.glob(warped_im)[0]
            func_data[day][run]['1warp'] = glob.glob(im_1warp)[0]
            if init:
                func_data[day][run]['init_interrun'] = init
        
    return func_data
  

ref_data = {dayref: {runref: func_data_DistCor[dayref][runref]}}

# # Within run alignment for runs of same day as ref_run (i.e., study reference run)
# mov_data = {day_ref: {run:d} for run,d in func_data_DistCor[day_ref].items() if not run==ref_run}
# temp = InterRunReg(mov_data, ref_data[day_ref][ref_run], work_dir)

# process other ref run (from sessions other than study ref_run)
if 'other_ref' in ref_dayrun:
    for dref,rref in ref_dayrun['other_ref'].items():
        mov_data = {dref: {rref: func_data_DistCor[dref][rref]}}
        temp = InterRunReg(mov_data, ref_data[dayref][runref], use_syn=True)

        # # now process all runs of the same session as other ref
        # mov_data2 = {dref: {run:d} for run,d in func_data_DistCor[dref].items() if not run==orun}
        # initf = func_data_DistCor[dref][orun]['interrun_mat']
        # temp = InterRunReg(mov_data2, ref_data[day_ref][ref_run], init=initf, work_dir=work_dir)
        

# run anatomy estimation workflow
eng = matlab.engine.start_matlab()
eng.cd(dir_m_scripts)

mprageised_im, wmseg_im, collected = eng.MPRAGEise(UNI_file, INV2_file, work_dir, nargout=3)

# if not pre-computed (i.e., not yet run) write to json file 
if not collected:
    with open(cmd_f, 'a+') as f:
        f.write('# MPRAGEised {}'.format(UNI_file))
        f.write('\r\r')


def anatBBR(func_data, mprageised_im, wmseg_im, init=None, work_dir=work_dir):
    
    data = copy.deepcopy(func_data)
    
    for day,runi in data.items():
        for run,d in runi.items():
        
            [base,in_filename,ext] = split_filename(d['temp0'])     
            omat = os.path.join(base, '{in_filename}_reg2anat_bbr.mat'.format(in_filename=in_filename))
            itkmat = os.path.join(base, '{in_filename}_reg2anat_bbr_itk.mat'.format(in_filename=in_filename))
            out_file = os.path.join(base, '{in_filename}_reg2anat_bbr{ext}'.format(in_filename=in_filename,ext=ext))
            
            if (not os.path.isfile(omat)) & (not os.path.isfile(out_file)):
                                
                addflags = '-i {}'.format(d['interrun_init']) if init else ''
                cmd = 'sk_ants_fsl_BBReg.sh -f {mprageised_im} -s {wmseg} -m {temp0} {addflags}'.format(mprageised_im=mprageised_im,
                                                                                                        temp0=d['temp0'],
                                                                                                        wmseg=wmseg_im,
                                                                                                        addflags=addflags)
            
                print('\nRunning:\n',cmd,'\n')
                res = Popen(cmd, shell=True, stdout=PIPE, cwd=work_dir).stdout.read()
                print(res)
                
                with open(cmd_f, 'a+') as f:
                    f.write(cmd)
                    f.write('\r\r')
                
            func_data[day][run]['bbr_mat'] = glob.glob(omat)[0]
            func_data[day][run]['bbr_itk'] = glob.glob(itkmat)[0]
            func_data[day][run]['bbr_warp'] = glob.glob(out_file)[0]
        
    return func_data

anatBBR(ref_data, mprageised_im, wmseg_im, work_dir=work_dir)


def antsReslice(func_data, ref_dayrun, mprageised_im, method=method, TR=TR, nthreads=16, work_dir=work_dir):
    
    data = copy.deepcopy(func_data)
    
    ref_day = list(ref_dayrun['ref'].keys())[0]
    ref_run = list(ref_dayrun['ref'].values())[0]
    temp0 = data[ref_day][ref_run]['temp0'] # Reference temp0 is not needed for nativeEPISpace results
    
    for day,runi in data.items(): 

        addflags = ''
        if day != ref_day:
            # Reference temp0 is needed for inter-session alignment results.
            # Using both u,v flags as we used SyN in the FineReg
            rref = ref_dayrun['other_ref'][day]
            addflags = '-u {intr} -r {rtemp0}'.format(intr=runi[rref]['interrun_mat'],
                                                      rtemp0=temp0)
            if '1Warp' in runi[rref]:
                im_1warp = '-v {}'.format(runi[rref]['1Warp'])
                addflags = ' '.join([addflags, im_1warp])
                
        for run,d in runi.items():
            
            [base,in_filename,ext] = split_filename(d['func'])     
            func_anat_space = os.path.join(base, '{in_filename}_{method}_MotDistCor_anatomySpace{ext}'.format(in_filename=in_filename,
                                                                                                              method=method,
                                                                                                              ext=ext))
            func_epi_space = os.path.join(base, '{in_filename}_{method}_MotDistCor_funcSpace{ext}'.format(in_filename=in_filename,
                                                                                                          method=method,
                                                                                                          ext=ext))
     
            if (not os.path.isfile(func_anat_space)) & (not os.path.isfile(func_epi_space)):
                        
                if method=='customreg':
                    mat = d['manual_mat']
                elif method == 'bbrreg':
                    mat = data[ref_day][ref_run]['bbr_itk']
                                                
                cmd = 'sk_ants_Realign_Reslice.sh -x {mat} -f {mprageised_im} -t {TR} -n {nthreads} -a {func_file} {addflags}'.format(mat=mat,
                                                                                                                                      temp0=temp0,
                                                                                                                                      mprageised_im=mprageised_im,
                                                                                                                                      TR=TR,
                                                                                                                                      nthreads=nthreads,
                                                                                                                                      func_file=d['func'],
                                                                                                                                      addflags=addflags)
               
                print('\nRunning:\n',cmd,'\n')
                res = Popen(cmd, shell=True, stdout=PIPE, cwd=work_dir).stdout.read()
                print(res)
        
                with open(cmd_f, 'a+') as f:
                    f.write(cmd)
                    f.write('\r\r')

                func_temp1 = glob.glob(os.path.join(base, '{in_filename}*_anatomySpaceAligned{ext}'.format(in_filename=in_filename,
                                                                                                           ext=ext)))[0]
                func_temp2 = glob.glob(os.path.join(base, '{in_filename}*_nativeEPISpace*Aligned{ext}'.format(in_filename=in_filename,
                                                                                                             ext=ext)))[0]      
                os.rename(func_temp1, func_anat_space)
                os.rename(func_temp2, func_epi_space)
    
            func_data[day][run]['func_anatSpace'] = glob.glob(func_anat_space)[0]
            func_data[day][run]['func_epiSpace'] = glob.glob(func_epi_space)[0]
        
    return func_data
    
func_data_aligned = antsReslice(func_data_DistCor, ref_dayrun, mprageised_im, method=method)

with open(var_json, 'w') as outfile:
    json.dump(func_data_aligned, outfile, indent=4)



