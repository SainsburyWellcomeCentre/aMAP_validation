function output_arg = nanIfEmpty( input_arg )
%NANIFEMPTY returns NaN if the input argument is empty, otherwise returns
%the input argument

if isempty(input_arg)
    output_arg = NaN;
else
    output_arg = input_arg;
end

end

