
function data = alexRegistrationFilter(data, method, despecle)
changeType = false;
if ~isa(data, 'double')
    changeType = true;
    origType = class(data);
    data = double(data);
end
if nargin<3
    despecle = true;
end
if nargin<2
    %method = 'zfilter+pseudoflatfield';
    method = 'pseudoflatfield';
end
switch method
    case 'pseudoflatfield'
        filterMethod=@(x) pseudoflatfieldcorrect(x, 15, 5);
    case 'zfilter'
        filterMethod=@(x) gaussian1DFilter(x, 8, 2);
    case 'pseudoflatfield+zfilter'
        filterMethod=@(x) gaussian1DFilter(pseudoflatfieldcorrect(x, 15, 5), 8, 2);
    case 'zfilter+pseudoflatfield'
        filterMethod=@(x) pseudoflatfieldcorrect(gaussian1DFilter(x, 8, 2), 15, 5);
    case 'pseudoflatfieldPreDespeckle'
        filterMethod=@(x) pseduoflatfieldWithPreDespeckle(x, 10, 15, 5);
    otherwise
        error('unknown filter method')
end

if despecle
    data = despeckleImageStack(data, 2);
end

data = filterData(data, filterMethod);

if changeType
    data = cast(data, origType);
end

end


function data= filterData(data, filterMethod)
I=double(data);
for ii=1:size(data, 3)
    %the following seems to be the main memory hog
    I(:,:,ii)=filterMethod(I(:,:,ii)); %#ok<PFBNS>
end

I=I./max(I(:))*65535; %convert to 16 bit, manually, as im2uint16 is doing something weird
data=uint16(I);

end

function I=pseudoflatfieldcorrect(I, sz, sigma)
I_filt=imfilter(I, fspecial('gaussian', sz, sigma));
I=I./(I_filt+1);
end

function I=pseduoflatfieldWithPreDespeckle(I, strelSize, sz, sigma)
s=strel('rectangle', [1 1]* strelSize);
I=imerode(I, s);
I=imdilate(I, s);
I=pseudoflatfieldcorrect(I, sz, sigma);
end
