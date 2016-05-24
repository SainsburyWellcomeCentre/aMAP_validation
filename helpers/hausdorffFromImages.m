function hausdorff = hausdorffFromImages(seg1, seg2)
%HAUSDORFFFROMIMAGES expects two boolean matrices (= 1 label) as input. Will see 0 as
%false and everything else as true (part of the region)

if ~all(size(seg1)==size(seg2))
    error('seg1 and seg2 must be of equal size')
end

seg1 = seg1>0;
seg2 = seg2>0;

%outline images to speed things up
seg1=bwperim(seg1, 8);
seg2=bwperim(seg2, 8);

[y1, x1] =find(seg1);
[y2, x2] =find(seg2);
hausdorff = nanIfEmpty(HausdorffDist([y1, x1], [y2, x2]));
end

