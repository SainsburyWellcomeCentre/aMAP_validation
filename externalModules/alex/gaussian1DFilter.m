function I=gaussian1DFilter(I, filtSig, dim)
    sz=filtSig*8;
    x=-ceil(sz/2):ceil(sz/2);
    H = exp(-(x.^2/(2*filtSig^2)));
    H = H/sum(H(:));
    if dim==1
        H=reshape(H,[length(H) 1 1]);
    elseif dim==2
        H=reshape(H,[1 length(H) 1]);
    elseif dim==3
        H=reshape(H,[1 1 length(H)]);
    end
    I=imfilter(I, H, 'same', 'replicate');

end
