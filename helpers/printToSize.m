function printToSize(figPath, width, height)
%PRINTTOSIZE Opens a matlab .fig file and saves a copy as pdf with the
%specified width and height in cm.
openfig(figPath);
cf = gcf;
cf.Units = 'centimeters';
oldPos = cf.Position;
cf.Position = [oldPos(1) oldPos(2) width height];
cf.PaperUnits = 'centimeters';
cf.PaperPositionMode = 'auto';
cf.PaperSize = [width height];
cf.PaperPosition = [0 0 width height];

print([figPath(1:end-3) 'pdf'], '-dpdf');
close
end

