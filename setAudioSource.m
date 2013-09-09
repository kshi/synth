%%%%% Script to help set micID %%%%%%%

a = audiodevinfo;
for i=1:length(a.input)
     disp([a.input(i).Name '   ID:' int2str(a.input(i).ID)]);
end
clear a;