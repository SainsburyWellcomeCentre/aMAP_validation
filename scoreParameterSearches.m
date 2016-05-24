parameters = sharedParams();
%nii4dDir = parameters.paramSearchCppDir;
cppDir = '/media/interim/CN/cn_segment/alignment3/resultsThresholdTest';
cppDir = '/media/brainDoh/CN/cn_segment/smallParameterSearch';
cppDirCont = dir(cppDir);
cppDirCont = {cppDirCont.name};
resampleDir = parameters.resampleDir;



i=1;
parameterSearchResults = parameterSearchResult.empty();
for fileName = cppDirCont
    fileName = char(fileName)
    cppPath = fullfile(cppDir,fileName);
    if ~(strendswith(cppPath,'CPP.nii.gz') || strendswith(cppPath,'_CPP.nii'))
        continue;
    end
    brainName = parameterSearchResult.getBrainName(fileName);
    brainNiiPath = fullfile(sharedParams.getBrainBaseDir(compID), sharedParams.getBrainFileName(brainName)); 
    currParameterSearchResult= parameterSearchResult...
        (cppPath, resampleDir, parameters.atlasPath, brainNiiPath, parameters.getStapleDir());
    parameterSearchResults(i)= currParameterSearchResult;
    parameterSearchResults(i)= parameterSearchResults(i).calculateScores();
    parameterSearchResults(i).segAnalyserObj.atlas = parameterSearchResults(i).segAnalyserObj.atlas.flushAtlas();
    i=i+1;
end

% %% individual file section is here...
% compID = 'BMF';
% resampleDir = parameters.resampleDir;
% filePath='~/CR_Syt6_cre_rfp_35_StitchedImagesPaths_Ch03_0-2399-noRep-12.5-ZsmoothedAffNoTrans_OstenRef_ARA_v2_rotatedFlipZXYZ12.5_ln6lp4sx10be0.95nmifbn128rbn128smo1_CPP.nii';
% filePath='/media/interim/CN/cn_segment/alignment3/resultsThresholdTest/ref_0_flo2_cpp_sx10_be0.95_lp5_smoo5_nmi64_fbn250rbn250.nii';
% filePath='/media/interim/CN/cn_segment/alignment3/resultsOptimizedParameters2/CR_Syt6_cre_rfp_35_StitchedImagesPaths_Ch03_0-2399-noRep-12.5-ZsmoothedAffNoTrans_OstenRef_ARA_v2_rotatedFlipZXYZ12.5_ln6lp4sx15be0.95nmifbn128rbn128smooR1smooF1_CPP.nii';
% filePath='/media/interim/CN/cn_segment/alignment3/resultsOptimizedParameters2/CR_Syt6_cre_rfp_35_StitchedImagesPaths_Ch03_0-2399-noRep-12.5-ZsmoothedAffNoTrans_OstenRef_ARA_v2_rotatedFlipZXYZ12.5_ln6lp5sx15be0.95nmifbn128rbn128smooR1smooF1_CPP.nii';
% filePath='/media/interim/CN/cn_segment/alignment3/resultsOptimizedParameters2/CR_Syt6_cre_rfp_35_StitchedImagesPaths_Ch03_0-2399-noRep-12.5-ZsmoothedAffNoTrans_OstenRef_ARA_v2_rotatedFlipZXYZ12.5_ln6lp5sx20be0.95nmifbn128rbn128smooR1smooF1_CPP.nii';
% filePath='/media/interim/CN/cn_segment/alignment3/resultsOptimizedParameters2/CR_Syt6_cre_rfp_35_StitchedImagesPaths_Ch03_0-2399-noRep-12.5-ZsmoothedAffNoTrans_OstenRef_ARA_v2_rotatedFlipZXYZ12.5_ln6lp5sx25be0.95nmifbn128rbn128smooR1smooF1_CPP.nii';
% filePath='/media/interim/CN/cn_segment/alignment3/resultsOptimizedParameters2/CR_Syt6_cre_rfp_35_StitchedImagesPaths_Ch03_0-2399-noRep-12.5-ZsmoothedAffNoTrans_OstenRef_ARA_v2_rotatedFlipZXYZ12.5_ln6lp6sx30be0.95nmifbn128rbn128smooR1smooF1_CPP.nii';
% brainNiiPath = '/media/interim/CN/cn_segment/alignment3/CR_Syt6_cre_rfp_35_StitchedImagesPaths_Ch03_0-2399-noRep-12.5-ZsmoothedAffNoTrans.nii';
% paramMap = containers.Map();
% paramMap('ln') = 6;
% paramMap('lp') = 4;
% paramMap('be') = 0.95;
% paramMap('smo') = 1;
% paramMap('nmi') = 128;
% paramMap('sx') = 15;
% [~,fName, fExt] = fileparts(filePath);
% %brainName = parameterSearchResult.getBrainName([fName,fExt]);
% brainName='CR_Syt6CreRfp_35';
% 
% currParameterSearchResult= parameterSearchResult...
%     (filePath, resampleDir, parameters.atlasPath, brainNiiPath, parameters.getStapleDir(), paramMap);
% currParameterSearchResult= currParameterSearchResult.calculateScores();