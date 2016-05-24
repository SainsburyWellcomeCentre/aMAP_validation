function hdScores = findHDforMaxDice(compSegTable, modality)
%FINDHDFORMAXDICE Returns a list of the hausdorff scores for the
%segmentation with the best dice score. Expects segmentation table from
%segAnalyze
%   Detailed explanation goes here
    
hdScores=NaN(size(compSegTable,1),1);

switch modality
    case 'STAPLE'
        dice=compSegTable.diceSTAPLE;
        hd = compSegTable.hdSTAPLE;
    case 'SBA'
        dice=compSegTable.diceSBA;
        hd=compSegTable.hdSBA;
    otherwise
        error(['Modality must be either STAPLE or SBA (was ' modality ')']);
end

for i=1:size(compSegTable,1);
    maxDicePos = find(dice{i}==max(dice{i}));
    possibleHD = hd{i}(maxDicePos);
    hdScores(i)=min(possibleHD);
end

