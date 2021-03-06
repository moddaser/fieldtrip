function test_nearest

% TEST test_nearest
% TEST nearest

% Use as
%   [indx] = nearest(array, val, insideflag, toleranceflag)

% these are some normal cases
assert(nearest([1 2 3], 1)==1)
assert(nearest([1 2 3], 2)==2)
assert(nearest([1 2 3], 3)==3)
assert(nearest([1 2 3], -inf)==1)
assert(nearest([1 2 3],  inf)==3)

% unsorted arrays should be supported
assert(nearest([1 3 2], -inf)==1)
assert(nearest([3 1 2], -inf)==2)
assert(nearest([3 1 2], 1)==2)

% outside the range
try
  nearest([1 2 3], 0, true);
  error('this should have returned an error');
end
try
  nearest([1 2 3], 4, true);
  error('this should have returned an error');
end

% just inside the tolerance range
assert(nearest([1 2 3], 0.5, true, true)==1);
assert(nearest([1 2 3], 3.5, true, true)==3);

% just outside the tolerance range
try
  nearest([1 2 3], 0.499, true, true);
  error('this should have returned an error');
end
try
  nearest([1 2 3], 3.501, true, true);
  error('this should have returned an error');
end

% new functionality of 'val' being a [minval maxval] input pair

assert(all(nearest(.1:.1:1.0,[.1 .3])==[1 3]))
assert(all(nearest(.1:.1:1.0,[.11 .3])==[2 3]))
assert(all(nearest(.1:.1:1.0,[.1 .29])==[1 2]))
assert(all(nearest(.1:.1:1.0,[0 .3])==[1 3]))
assert(all(nearest(.1:.1:1.0,[.11 .29])==[2 2]))
assert(all(nearest(.1:.1:1.0,[-inf 1])==[1 10]))
assert(all(nearest(.1:.1:1.0,[.79 inf])==[8 10]))
assert(all(nearest(.1:.1:1.0,[.8 10])==[8 10]))
assert(all(nearest(.1:.1:1.0,[-2 8])==[1 10]))
assert(all(nearest(.1:.1:1.0,[.79 .99])==[8 9]))
assert(all(nearest(.001:.001:.01,[.002 .003])==[2 3]))
assert(all(nearest(.001:.001:.1,[0 1])==[1 100]))

try
  nearest(.1:.1:1.0,[3 8]);
catch me
  if ~strcmp(me.message,'The limits you selected are outside the range available in the data')
    error('wrong error message in nearest')
  end
end





