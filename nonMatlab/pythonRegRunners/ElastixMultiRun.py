from subprocess import STDOUT, check_output as ccall, CalledProcessError
import argparse
import os
import sys
from os import listdir, path, mkdir
from os.path import isfile, join, basename

elastixExec = '/home/cniedwo/elastix_4.8/bin/elastix'
trfxExec = '/home/cniedwo/elastix_4.8/bin/transformix'
elastixParams = ['/home/cniedwo/MatlabCode/segAnalyze/data/elastixParams/poAffine.txt', '/home/cniedwo/MatlabCode/segAnalyze/data/elastixParams/poSpline.txt']

def mainFunc():
    parser = argparse.ArgumentParser(description='Run Elastix registration protocol for all images in the directory')
    parser.add_argument('--refDir', '-r', dest='refDir', required = True, \
    help='The directory containing the reference images.')
    parser.add_argument('--floatFile', '-f', dest='floatFile', required = True, \
    help='Path to the floating image.')
    parser.add_argument('--outDir', '-o', dest='outDir', required = False, \
    help='Path to store the output images/parameters (default: current dir)', default=os.getcwd())
    parser.add_argument('--atlas', '-a', dest='atlas', required = False, \
    help='Path to the atlas segmentation file which will be resampled with the CPP file from the registration.', default=None)

    args = parser.parse_args()

    refImgs = [join(args.refDir, File) for File in listdir(args.refDir)]
    refImgs = [img for img in refImgs if isfile(img) and img.endswith('.nii')]

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
        baseName = basename(rfPair[0])[:-4]+'_'+basename(rfPair[1])[:-4]
        currOutDir = join(args.outDir,baseName)
        mkdir(currOutDir)
        elastixLogPath = join(currOutDir,basename+'_LOG.txt')
        elastixCommand = elastixExec+' -f '+rfPair[0]+' -m '+rfPair[1]+' -p '.join(elastixParams)+' -o '+currOutDir
        elastixLog = ''
        try:
            elastixLog = ccall(elastixCommand, shell=True, stderr=STDOUT)
        except CalledProcessError as err:
            writeAndDie(err.output, elastixLogPath)   
        with open(elastixLogPath, 'w') as f:
            f.write(elastixLog)
        
        transformParameterFiles = ['TransformParameters.0.txt', 'TransformParameters.1.txt']
        transformParameterFiles = [join(currOutDir,tpFile) for tpFile in transformParameterFiles]
        for tpFilePath in transformParameterFiles:
	  with open(tpFilePath,'r') as tpFile:
	    tpCont = tpFile.read()
	  tpCont = tpCont.replace('(FinalBSplineInterpolationOrder 3)', '(FinalBSplineInterpolationOrder 1)')
	  with open(tpFilePath,'w') as tpFile:
	    tpCont = tpFile.write(tpCont)
        
        if args.atlas is not None:
	  atlasOutDir = join(currOutDir,'atlas')
	  mkdir(atlasOutDir)
          trfxCmd = trfxExec+' -in '+args.atlas+' -out '+atlasOutDir+' tp '+transformParameterFiles[-1]
          try:
            resampleLog = ccall(trfxCmd, shell=True, stderr=STDOUT)
          except CalledProcessError as err:
            writeAndDie(err.output, join(atlasOutDir,'ERR.txt'))


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

if __name__ == "__main__":
    mainFunc()