function test_bug1759
% TEST test_bug1759

% Sparse matrix multplication results in slightly different results than nonsparse
% http://bugzilla.fcdonders.nl/show_bug.cgi?id=1759
load test_bug1759;

tmp{1} = tra*dat;
tmp{2} = sparse(tra)*dat;

assert(identical(tmp{1}, tmp{2}, 'reltol', 0.0001));
end