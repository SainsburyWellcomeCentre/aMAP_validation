function imgOut = cutImg( imgIn, cutSize)
%CUTIMG Designed to be used with a binary image, will return a square
%section centered on the center of mass of the input image

[imgX, imgY]=find(imgIn);
minX=max(1,round(mean(imgX)-cutSize(1)/2));
maxX=min(size(imgIn,1), round(mean(imgX)+cutSize(1)/2));

minY=max(1,floor(mean(imgY)-cutSize(2)/2));
maxY=min(size(imgIn,2), floor(mean(imgY)+cutSize(2)/2));
cutOutImg = imgIn(minX:maxX,minY:maxY);
imgOut = uint8(zeros(cutSize));
imgOut(1:size(cutOutImg,1), 1:size(cutOutImg,2)) = cutOutImg;

end

