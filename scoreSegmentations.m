%% Initialization section. Make sure you have edited globalData.yml and registrations.yml to fit your system!
% set the string used to initialize sharedParams to the name of your own
% registration, as defined in the registrations.yml
parameters = sharedParams('128HistoBins_Ln6Lp4Smo1');
%parameters = sharedParams('ElastixTestNiftyRegParams');

% set these to determine whether to score manual and/or automated
% segmentations
scoreManual = true;
scoreAutomated = true;

% set these to run either on the full z-range (empty string) or on subsets.
% Note: You will have to create agreement segmentations for the desired
% ranges before you can score them (using the createAgreementSegs.m script)
range=[]
% range = 'Quartiles';
% range = 3;

%% Run on section
segAnalysers = segAnalyser.empty();
for i = 1:numel(parameters.brainNames)
    currAtlasPath = fullfile(parameters.registeredAtlasBaseDir, parameters.registeredAtlasPaths{i});
    segAnalysers(i) = calculateRegistrationScores(parameters.brainNames{i}, currAtlasPath, parameters.getStapleDir(range), parameters, scoreManual, scoreAutomated);
    %segAnalysers(i).atlas.atlas.img = []; %clear the registered atlas to save memory
end
