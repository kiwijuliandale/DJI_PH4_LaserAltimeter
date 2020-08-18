function xloc = slmsolve(model,yvalue)
% slmsolve: all locations (roots) where an SLM or PP spline takes on a specified value
% usage: xloc = slmsolve(model)
% usage: xloc = slmsolve(model,yvalue)
%
% Search for all real "roots" or solutions of an SLM function or any PP form
% spline, such that f(x) == yvalue. slmeval also does this, but it returns
% only one solution, the left-most (closest to -inf) real-valued solution.
%
% Arguments: (input)
%  model - A slm model as produced by slmengine,
%        also any pp form spline, as produced by spline
%        or pchip.
% 
%  yvalue - any scalar numeric value
%        If not provided or empty, then 0 is assumed.
%
% Arguments: (output)
%  xloc - A row vector of solutions, such that model(xloc) == yvalue.

% was yvalue supplied?
if (nargin < 2) || isempty(yvalue)
  yvalue = 0;
elseif ~isscalar(yvalue) || ~isnumeric(yvalue)
  error('yvalue must be scalar and numeric if supplied.')
end

% we will do all processing on the spline as a pp form for simplicity
if strcmp(model.form,'slm')
  % convert the slm to a pp form
  model = slm2pp(model);
end

% how many segments in the model?
nseg = model.pieces;

% extract the breaks for this model
breaks = model.breaks;

% extract the coefficients, and offset the constant term by yvalue
coefs = model.coefs;

% this turns the problem into a simple one of all roots, where we need
% only search for a value that makes the function zero.
coefs(:,end) = coefs(:,end) - yvalue;

% since we do not know how many roots we will find, store them
% all in a cell array, to be flattened later. We need only have
% nseg cells in the cell array, where nseg is the number of segments.
xloc = cell(1,nseg);

% tolerance on the roots found, to exclude multiple findings
% of the same root, also on the imaginary part of any complex
% roots. The complex tolerance is different, since this will only
% be an issue for double roots. It will be scaled for each knot
% interval.
xtol = 1e-14*mean(diff(breaks));
ctol = 1e-8;

% just loop over each interval
for iseg = 1:nseg
  p = coefs(iseg,:);
  
  % the width of the current interval
  bi = breaks(iseg);
  h = breaks(iseg + 1) - bi;
  
  % use roots as the fundamental solver engine
  xr = roots(p);
  
  % exclude roots with a significant complex part.
  xr(abs(imag(xr)) > ctol*h) = [];
  
  % any imaginary parts that remain were insignificant
  xr = real(xr);
  
  % exclude any roots that fall outside of the current interval
  % by more than xtol.
  xr(xr < -xtol) = [];
  xr(xr > (h + xtol)) = [];
  
  % shift the roots found
  xr = xr + bi;
  
  % tweak to ensure they fell in the current interval
  xr = min(max(xr,bi),breaks(iseg + 1));
  
  % save any roots we found
  if ~isempty(xr)
    xloc{iseg} = xr(:)';
  end
end

% concatenate all cells into a flat vector of solutions.
% the unique will catch exact reps, as well as sort the roots.
xloc = unique(cell2mat(xloc));

% coallesce replicates, using xtol to distinguish replicates
% a simple loop will suffice here.
nx = numel(xloc);
if nx > 1
  for k = 2:nx
    if (xloc(k) - xloc(k-1)) < (2*xtol)
      xloc(k) = (xloc(k) + xloc(k-1))/2;
      xloc(k-1) = NaN;
    end
  end
  xloc(isnan(xloc)) = [];
end



