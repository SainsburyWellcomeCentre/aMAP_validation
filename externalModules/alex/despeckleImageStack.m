function I = despeckleImageStack(I, strelSize)
% DESPECKLEIMAGESTACK despeckles an image stack by erosion and dilation in
% xy
    s=strel('disk', strelSize, 0);
    swb=SuperWaitBar(size(I, 3), 'Despeckling');
    for ii=1:size(I, 3)
        I(:,:,ii)=imerode(I(:,:,ii), s);
        I(:,:,ii)=imdilate(I(:,:,ii), s);
        swb.progress;
    end
    delete(swb)
end