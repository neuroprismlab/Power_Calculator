function [tfced,comps,comp_sizes] = matlab_tfce_transform(img,varargin)
% Generalized for connectivity using code from https://github.com/markallenthornton/MatlabTFCE
% Matrix TFCE parameter defaults from https://github.com/MRtrix3/mrtrix3/blob/master/cmd/connectomestats.cpp
% 
% Specify: 'matrix' for matrix, 'image' for 2 or 3D image
% TODO: other weightings as optional args
%
%OLD MATLAB_TFCE_TRANSFORM performs threshold free cluster enhancement
%   [tfced] = matlab_tfce_transform(img,H,E,C,dh) performs threshold
%   free cluster enhancement on 'img' as per Smith & Nichols (2009).
%   -- img the 3D image to be transformed
%   -- H height exponent
%   -- E extent exponent
%   -- C connectivity/"neighborhood" (if image)
%   -- dh size of steps for cluster formation
%   -- tfced output tfce statistic (upper triangular)

%% **Set Parameters**
% Create input parser
p = inputParser;
% Add parameters with default values
addOptional(p, 'dh', 0.1);
addOptional(p, 'H', 3.0);
addOptional(p, 'E', 0.4);
% Parse the input arguments
parse(p, varargin{:});
% Get the parameters
dh = p.Results.dh; % Threshold step size
H = p.Results.H;
E = p.Results.E;

% set cluster thresholds
% The max_thresh is set at 5000 for test script scenarios where the effect size is
% too high. To be correct, no empirical application should yield more than
% 100
img(img > 1000) = 100;

% Small perturbation introduced to help the test case (things not being all
% equal)
%perturbation = rand(size(img)) * 1e-15; % Small perturbation for numerical stability
%img = img + (rand(size(img)) * 1e-15);
%img = img + tril(perturbation, -1) + tril(perturbation, -1)'; % Ensure symmetry
%img(logical(eye(size(img)))) = 0; % Set diagonal to zero (for graphs)
threshs = 0:dh:max(img(:));
threshs = threshs(2:end);
ndh = length(threshs);


% find positive elements (voxels/edges greater than first threshold)
n_elements = length(img(:));

% get connected components
%   cc.PixeldxList = IDs of all edges for each cluster in a cell (for each dh)
%   cc.NumObjects = number of components (for each dh)
[comps,comp_sizes] = arrayfun(@(x) get_components2(bsxfun(@ge,img,x),1), threshs);
cc = arrayfun(@(x) get_component_IDs(bsxfun(@ge,img,threshs(x)),comps{x},comp_sizes{x}), [1:ndh]);


% calculate TFCE statistic
store_cell = cell(ndh, 1);

vals = zeros(n_elements,1);
for h = 1:ndh
    clustsize = zeros(n_elements,1);
    ccc = cc(h);
    elempercc = cellfun(@numel,ccc.PixelIdxList);
    for c = 1:cc(h).NumObjects
        clustsize(ccc.PixelIdxList{c}) = elempercc(c);
    end
    % calculate transform
    curvals = (clustsize.^E).*(threshs(h)^H);
    vals = vals + curvals;

    store_cell{h} = clustsize;
end

tfced = NaN(size(img));
tfced(:) = vals.*dh;
tfced = triu(tfced) + triu(tfced, 1)';

if isempty(comps)
    comps = zeros(1, size(img, 1)); % Neutral output (no clusters)
else
    if iscell(comps(1))  % Handle nested cell case
        comps = comps(1);
        comps = comps{1};
    else
        comps = comps{1}; % Normal cell extraction
    end
end

if ~isempty(comp_sizes)
    comp_sizes = comp_sizes{1};
else
    comp_sizes = 0;
end

end


% checked TFCE calculation manually:
% given 33 contiguous edges with value 1
% dh=0.1 so 10 levels from 0 to 1 (not incl. 0)
% height of each edge at each dh = .1*i, weight H=3
% extent at each dh = 33, weighting E = 0.4
%for i=1:10; c(i)=33^.4*(.1*i)^3; end
%sum(c)*.1

% old code for getting numobjects after the fact
% for h = 1:ndh
%     cc(h).PixelIdxList={cc2(h)};
%     cc(h).PixelIdxList={cc2(h)};
% end
% NumObjects=arrayfun(@(x) length(cc(x).PixelIdxList), 1:length(cc));
% cc.NumObjects=NumObjects;

