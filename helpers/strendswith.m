function result = strendswith(s, suffix)
%Checks whether a string (s) ends with a specified suffix
%

strL = length(s);
sfxL = length(suffix);

result = (strL>=sfxL...
       && strcmp(s(strL-sfxL+1:strL), suffix))...
       || isempty(suffix);