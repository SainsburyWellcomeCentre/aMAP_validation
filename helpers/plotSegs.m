function  plotSegs(dataArr1, dataArr2, dataArr3, segRegionArr1, segRegionArr2, segRegionArr3, regionGroups, dotSize, proxCutoff, title, outdir, prefix)
%PLOTSEGS Simple helper function to make ploting the segmentation scores 
%   easier.
for i = 1:numel(regionGroups)
    plotCell={numel(regionGroups{i}),1};
    k=1;
    for j = 1:numel(regionGroups{i})
        manVals = [dataArr1(segRegionArr1==regionGroups{i}{j})]';
        plotCell{k}=manVals;
        k=k+1;
        
        if ~isempty(dataArr2)
            compVals = [dataArr2(segRegionArr2==regionGroups{i}{j})]';
            plotCell{k}=compVals;        
            k=k+1;
        end
        if ~isempty(dataArr2)
            printStats(compVals, regionGroups{i}{j}, true);
        end
        printStats(manVals, regionGroups{i}{j}, false);
        
        if ~isempty(dataArr3)
            compVals2 = [dataArr3(segRegionArr3==regionGroups{i}{j})]';
            plotCell{k}=compVals2;
        k=k+1;
        end
    end
    clCell = {[0 0 0]};
    if ~isempty(dataArr2)
        clCell = [clCell [0 1 0]];
    end
    if ~isempty(dataArr3)
        clCell = [clCell [0 1 1]];
    end
    clCell = repmat(clCell, 1, numel(regionGroups{i}));
    neatDotPlot(plotCell, [], 'color', clCell, 'markerSize', dotSize, 'proximityCutoff', proxCutoff);
    cf = gcf;
    %cf.Children.Title.String=strjoin([{title} regionGroups{i}], ' ');
    
    ax = gca;
    if isempty(dataArr3)
        ax.XTick = [1.5:2:2*numel(regionGroups{i})-0.5];
    else
        ax.XTick = [2:3:3*numel(regionGroups{i})-1];
    end
    ax.XTickLabel = regionGroups{i};
    
    figname=fullfile(outdir, [prefix title(1:3) strjoin(regionGroups{i}, '-') '.fig'])
    savefig(figname);
    close
    printToSize(figname, 19,7);
end


end

function printStats(data, regionName, comp)
if comp
    rater='automated';
else
    rater='manual';
end
disp(['Statistics for ' rater ' segmentation of ' regionName ':']);
fprintf('%s %g \n', 'Min: ',min(data));
fprintf('%s %g \n', 'Max: ',max(data));
fprintf('%s %g \n', 'Quartile1: ',quantile(data,0.25));
fprintf('%s %g \n', 'Median: ',median(data));
fprintf('%s %g \n\n', 'Quartile3: ',quantile(data,0.75));
end