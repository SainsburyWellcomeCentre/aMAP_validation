function [resImg1, resImg2] = padToLarger(img1, img2)
%PADTOLARGER Takes two 2d matrices and makes them the same width and height
%by 0-padding if necessary (top-left-aligned)

max1 = max(size(img1, 1), size(img2, 1));
max2 = max(size(img1, 2), size(img2, 2));

resImg1 = zeros(max1, max2);
resImg2 = zeros(max1, max2);

resImg1(1:size(img1, 1), 1:size(img1, 2)) = img1;
resImg2(1:size(img2, 1), 1:size(img2, 2)) = img2;

end

