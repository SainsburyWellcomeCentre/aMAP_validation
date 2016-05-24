function dice = diceScore(seg1, seg2)
%DICESCORE Calculates the dice score of two images. Expects two boolean 2D
%  matrices (= 1 label) as input. Will see 0 as false and everything else
%  as true (part of the region).

if ~all(size(seg1)==size(seg2))
    error('seg1 and seg2 must be of equal size')
end

seg1 = seg1>0;
seg2 = seg2>0;

intersect=sum(seg1 & seg2); 
nVoxels1 = sum(seg1); % the number of voxels in m
nVoxels2 = sum(seg2); % the number of voxels in o
dice = (2*intersect)/(nVoxels1+nVoxels2);

end

