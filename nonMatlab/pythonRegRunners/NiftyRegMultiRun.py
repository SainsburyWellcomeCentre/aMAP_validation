from subprocess import STDOUT, check_output as ccall, CalledProcessError
import argparse
import os
import sys
from os import listdir, path
from os.path import isfile, join, basename

f3dExec = 'reg_f3d '
f3dExec = '~/niftyreg/niftyreg_build150331/reg-apps/reg_f3d '
aladinExec = 'reg_aladin '
resampleExec = 'reg_resample '
#f3d_params = ['-ln 6','-lp 6', '-sx -30', '-be 0.95', '--nmi', '--fbn 128', '--rbn 128', '-smooR -1', '-smooF -1', '-omp 20'] #check floating bin and such...
#f3d_params = ['-ln 6','-lp 4', '-sx -10', '-be 0.97', '--nmi', '--fbn 128', '--rbn 128', '-smooR -1', '-smooF -1', '-omp 20'] #check floating bin and such...
f3d_params = ['-ln 6','-lp 4', '-sx -10', '-be 0.95', '--nmi', '--fbn 128', '--rbn 128', '-smooR -1', '-smooF -1', '-omp 20'] #check floating bin and such...
aladin_params = ['-ln 6','-lp 4']
resample_params = ['-inter 0']

def mainFunc():
    parser = argparse.ArgumentParser(description='Run standard Registration protocol for all images in the directory')
    parser.add_argument('--refDir', '-r', dest='refDir', required = True, \
    help='The directory containing the reference images.')
    parser.add_argument('--floatFile', '-f', dest='floatFile', required = True, \
    help='Path to the floating image.')
    parser.add_argument('--outDir', '-o', dest='outDir', required = False, \
    help='Path to store the output images/parameters (default: current dir)', default=os.getcwd())
    parser.add_argument('--atlas', '-a', dest='atlas', required = False, \
    help='Path to the atlas segmentation file which will be resampled with the CPP file from the registration.', default=None)
    parser.add_argument('--resOnly', '-m', dest='resOnly', required = False, action='store_true',\
    help='Resample atlas only, relying on previous registration run.', default=False)

    args = parser.parse_args()

    refImgs = [join(args.refDir, File) for File in listdir(args.refDir)]
    refImgs = [img for img in refImgs if isfile(img) and (img.endswith('.nii') or img.endswith('.nii.gz'))]

    if not refImgs:
        print('Couldn\'t find any reference images')
        return

    if not path.isfile(args.floatFile):
        print('Coudln\'t find the float image')

    refImgs.sort(key=str.lower)

    refFloatPairs = [[refImg, args.floatFile] for refImg in refImgs]

    f3dParStr = paramListToShortString(f3d_params)
    aladinParStr = paramListToShortString(aladin_params)
    for rfPair in refFloatPairs:
        baseName = basename(rfPair[0])[:nameEnd(rfPair[0])]+'_'+basename(rfPair[1])[:nameEnd(rfPair[1])]
        cppPath = join(args.outDir,baseName+'_'+f3dParStr+'_CPP'+'.nii')
        affPath = join(args.outDir,baseName+'_'+aladinParStr+'_AFF'+'.txt')
        imgsArg = ['-ref '+rfPair[0],'-flo '+rfPair[1]]
        f3dArg = ['-cpp '+cppPath]
        affArg = ['-aff '+affPath]
        
        regAladinCommand = aladinExec+' '.join(imgsArg+aladin_params+affArg)
        regF3dCommand = f3dExec+' '.join(imgsArg+f3d_params+affArg+f3dArg)
        aladinLogPath = affPath[0:-4]+'_LOG.txt'
        f3dLogPath = cppPath[0:-4]+'_LOG.txt'
        aladinLog=''
        f3dLog=''
        
        if args.resOnly is False:
	  
	  if not path.isfile(affPath):
	    try:
		aladinLog = ccall(regAladinCommand, shell=True, stderr=STDOUT)
	    except CalledProcessError as err:
		writeAndDie(err.output, aladinLogPath)   
	    with open(aladinLogPath, 'w') as f:
		f.write(aladinLog)
	  
	  try:
	      print(regF3dCommand)
	      f3dLog = ccall(regF3dCommand, shell=True, stderr=STDOUT)
	  except CalledProcessError as err:
	      continue
	      writeAndDie(err.output, f3dLogPath)    
	  with open(f3dLogPath, 'w') as f:
	      f.write(f3dLog)
	      
        if args.atlas is not None:
            mapPath = join(args.outDir,baseName+'_'+f3dParStr+'_MAP'+'.nii.gz')
            resampleArgs = ['-ref '+rfPair[0],'-flo '+args.atlas,'-trans '+cppPath,'-res '+mapPath]
            resampleCommand = resampleExec+' '.join(resampleArgs+resample_params)
            #print(resampleCommand)
            try:
                resampleLog = ccall(resampleCommand, shell=True, stderr=STDOUT)
            except CalledProcessError as err:
                writeAndDie(err.output, mapPath[0:-4]+'ERR.txt')
        #print(regAladinCommand)
        #print(regF3dCommand)


######################################


def paramListToShortString(paramList):
    """
    :rtype:string
    """
    paramStr = ''.join(paramList)
    paramStr = ''.join(paramStr.split())
    paramStr = paramStr.replace('-','')
    return paramStr

def writeAndDie(string, outFile):
    print('Error in Executing a command:\n')
    print(string)
    with open(outFile, 'w') as f:
        f.write(string)
    sys.exit(1)
    
def nameEnd(niiName):
  """
  :rtype:int
  """
  if niiName.endswith('.nii'):
    return -4
  elif niiName.endswith('.nii.gz'):
    return -7
  else:
    raise TypeError('Only use this function on .nii or .nii.gz files (Input was '+niiName+')')

if __name__ == "__main__":
    mainFunc()