function image = applyMinMax16BitStack(image, min, max)
%APPLYMINMAX16BITSTACK Converts the input to a 16 bit stack by scaling the
%values between min and max to the whole 16bit range
image=double(image);
image = ((image-min)/(max-min))*65535;
image=uint16(image);
end

