%% make heatmap 

%% Load the struct
p.list_cal = load('list_cal_complete.mat');
p.list_nrf = load('list_nrf_complete.mat');

% make matrix
p.diff_square = cell(2,1);
calories = round(cell2mat(p.list_cal.list_cal_complete(:,4)));
diff_square =[];

for r = 1:length(calories)
    for c = 1:length(calories)
        diff_square(r,c) = calories(r) - calories(c);
    end
end

p.diff_square{1}=diff_square; 

%% NRF

nrfs = round(cell2mat(p.list_nrf.list_nrf_complete(:,4)));
diff_square =[];

for r = 1:length(nrfs)
    for c = 1:length(nrfs)
        diff_square(r,c) = nrfs(r) - nrfs(c);
    end
end

p.diff_square{2}=diff_square; 



% Extract the matrices
calories_diff = abs(p.diff_square{1}); % Convert Calories condition to absolute values
nrf_diff = abs(p.diff_square{2}); % Convert NRF condition to absolute values

%% Order both matrices by sorting the underlying vectors
% Sort ascending and get permutation indices
[cal_sorted, cal_order] = sort(calories, 'ascend');
[nrf_sorted, nrf_order] = sort(nrfs,     'ascend');

% Apply the same row/column permutation to the matrices
calories_diff_ord = calories_diff(cal_order, cal_order);
nrf_diff_ord      = nrf_diff(nrf_order, nrf_order);

%% Heatmap – Calories

% Sequential orange (light -> dark)
n = 256;
c_low  = [255, 247, 236]/255;  % very light cream
c_mid  = [253, 174, 107]/255;  % orange
c_high = [230,  85,  13]/255;  % deep orange

cmap_or = interp1([0 0.5 1], [c_low; c_mid; c_high], linspace(0,1,n));


figure;
imagesc(calories_diff_ord);
axis square; 
colorbar;
colormap(cmap_or);
set(gca, 'XTickLabel', []);
set(gca, 'YTickLabel', []);

xlabel('Stimulus 1'); 
ylabel('Stimulus 2');
title('Stimulus Differences – Calories (|Δ|)');





%% Heatmap – NRF
% Green colormap (light -> dark)
n = 256;
c_low  = [245, 252, 245]/255;  % very light greenish
c_mid  = [161, 217, 155]/255;  % soft green
c_high = [ 35, 139,  69]/255;  % dark green

cmap = interp1([0 0.5 1], [c_low; c_mid; c_high], linspace(0,1,n));

figure;
imagesc(nrf_diff_ord);
axis square; 
colorbar;
colormap(cmap);
set(gca, 'XTickLabel', []);
set(gca, 'YTickLabel', []);

xlabel('Stimulus 1'); 
ylabel('Stimulus 2');
title('Stimulus Differences – NRF (|Δ|)');

