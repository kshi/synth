%cMost

ans = [];
z = who;
if length(z) < 7
    return
end
if z{7} == 'h'
    z(6) = [];
    clear(z{:})
    clear('z')
else
    clear(z{:})
end
