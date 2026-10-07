%% extract data for analysis
clear all
close all
clc

%% set paths

parent_dir = pwd; % task directory
function_dir = fullfile(parent_dir, '\Behavioural\functions');
addpath(function_dir);

proj_dir = fileparts(parent_dir);

code_directory = [parent_dir '\Behavioural\analysis'];
figure_directory = [parent_dir '\Behavioural\figures'];
pre_data_directory = [parent_dir '\Behavioural\MetaBites_task\taskcode\runtask\Data'];
post_data_directory = fullfile(parent_dir, '..', 'Analysis', 'MetaBites_analysis', 'Data');
post_data_directory = char(java.io.File(post_data_directory).getCanonicalPath());

%% define subjects and other settings
subject_ids = [3003 3006:3010 3012:3034 3036:3038]; % all subject IDs to be analysed, excluded two for missing questionnaires and bad performance
subj_prefix = 'MetaBitesData_';
% numbers for table allocation
nSubjects = length(subject_ids);
nBlocks = 5;

%% allocate and start summary table
% Define the fixed columns
fixedColumns = {'sID', 'correct_cal', 'correct_nrf', 'RT_cal', 'RT_nrf', 'confidence_cal', 'confidence_nrf', 'RT_conf_cal', 'RT_conf_nrf', 'threshold_cal', 'threshold_nrf', 'SB_pre_cal', 'SB_pre_nrf'};

% Initialize the dynamic columns based on the fixed number of blocks
SBColumns = cell(1, 2 * nBlocks);
for i = 1:nBlocks
    SBColumns{2*i-1} = ['SB_cal_', num2str(i)];
    SBColumns{2*i} = ['SB_nrf_', num2str(i)];
end

% Combine fixed and dynamic columns
allColumns = [fixedColumns, SBColumns, {'SB_post_cal', 'SB_post_nrf'}];

% Create an empty table with the specified columns
summaryTable = array2table(nan(nSubjects, length(allColumns)), 'VariableNames', allColumns);
summaryTable.sID = subject_ids';
TrialMaster = table();
ratings_summary = table();  
trialratings_summary = table();  

%% load in files

for n = 1:nSubjects
    
% file path per subject
subject_data_file = [pre_data_directory '\' subj_prefix int2str(subject_ids(n)) '.mat']; 
% load in results struct
load(subject_data_file)



%%
%%%%%%%%%% Trial level excel file %%%%%%%%%%

% select relevant data
% subject number
sID = results.p.subID;
sIDcol = cell2table(repmat({sID}, results.p.totalNumTrial, 1), 'VariableNames', {'sID'});
% split per condition
calIndices = (results.WhichCondition == 1);
nrfIndices = (results.WhichCondition == 2);
% trial
trial = array2table(results.trial', 'VariableNames', {'trial'});
% condition number
condition = array2table(results.WhichCondition', 'VariableNames', {'condition'});
% response
response = array2table(results.Responses', 'VariableNames', {'response'});
% correct
correct = array2table(results.Corrects', 'VariableNames', {'correct'});
% RT
RT_mili = results.RTS';
RT_sec = RT_mili / 1000;
RT = array2table(round(RT_sec, 4), 'VariableNames', {'RT'});
% confidence
confidence = array2table(results.Confidence', 'VariableNames', {'confidence'});
% confidence RT
RT_conf = array2table(results.RT_Confidence', 'VariableNames', {'RT_conf'});
% difference target
stimdiff = array2table(results.DifferenceTarget', 'VariableNames', {'stimdiff'});
% z_score
for d = 1:length(results.DifferenceTarget)
    if calIndices(d) == 1   % this element belongs to "calories"
        mu = mean(results.DifferenceTarget(calIndices), 'omitnan');
        sigma = std(results.DifferenceTarget(calIndices), 'omitnan');
        z_diff(d) = (results.DifferenceTarget(d) - mu) / sigma;  
    elseif nrfIndices(d) == 1   % this element belongs to "nrf"
        mu = mean(results.DifferenceTarget(nrfIndices), 'omitnan');
        sigma = std(results.DifferenceTarget(nrfIndices), 'omitnan');
        z_diff(d) = (results.DifferenceTarget(d) - mu) / sigma;
    end
end
z_stimdiff = array2table(z_diff', 'VariableNames', {'z_stimdiff'});
% reversal
reversal = array2table(results.Reversal', 'VariableNames', {'reversal'});
% SB
SBs = array2table(results.Self_belief', 'VariableNames', {'SBs'});
% RT SB
RT_SBs = array2table(results.RT_Self_belief', 'VariableNames', {'RT_SBs'});

% put together table
data = [sIDcol, trial, condition, response, correct, RT, confidence, RT_conf, stimdiff, z_stimdiff, reversal, SBs, RT_SBs];
excludedRows = find(data.RT < 0.05);
data = data(data.RT > 0.05, :);

% Append current subject's data to master table
TrialMaster = [TrialMaster; data];


%%
%%%%%%%%%% one participant summary row%%%%%%%%
% exclude too fast reaction time
nrfIndices(excludedRows) = 0;
calIndices(excludedRows) = 0;

% average correct (should be about 71%)
cal_avg_correct = mean(results.Corrects(calIndices), 'omitnan');
nrf_avg_correct = mean(results.Corrects(nrfIndices), 'omitnan');
summaryTable.correct_cal(n) = cal_avg_correct;
summaryTable.correct_nrf(n) = nrf_avg_correct;
% average RT
cal_avg_RT = mean(RT_sec(calIndices), 'omitnan');
nrf_avg_RT = mean(RT_sec(nrfIndices), 'omitnan');
summaryTable.RT_cal(n) = cal_avg_RT;
summaryTable.RT_nrf(n) = nrf_avg_RT;

% average confidence
cal_avg_confidence = mean(results.Confidence(calIndices), 'omitnan');
nrf_avg_confidence = mean(results.Confidence(nrfIndices), 'omitnan');
summaryTable.confidence_cal(n) = cal_avg_confidence;
summaryTable.confidence_nrf(n) = nrf_avg_confidence;

% confidence per accuracy and condition
cal_correct_conf = mean(results.Confidence(calIndices & results.Corrects == 1), 'omitnan');
cal_incorrect_conf = mean(results.Confidence(calIndices & results.Corrects == 0), 'omitnan');
nrf_correct_conf = mean(results.Confidence(nrfIndices & results.Corrects == 1), 'omitnan');
nrf_incorrect_conf = mean(results.Confidence(nrfIndices & results.Corrects == 0), 'omitnan');
% into table
summaryTable.conf_correct_cal(n) = cal_correct_conf;
summaryTable.conf_incorrect_cal(n) = cal_incorrect_conf;
summaryTable.conf_correct_nrf(n) = nrf_correct_conf;
summaryTable.conf_incorrect_nrf(n) = nrf_incorrect_conf;

% average RT confidence
cal_avg_RT_conf = mean(results.RT_Confidence(calIndices), 'omitnan');
nrf_avg_RT_conf = mean(results.RT_Confidence(nrfIndices), 'omitnan');
summaryTable.RT_conf_cal(n) = cal_avg_RT_conf;
summaryTable.RT_conf_nrf(n) = nrf_avg_RT_conf;

% RT by accuracy and condition
cal_correct_RT = mean(RT_sec(calIndices & results.Corrects == 1), 'omitnan');
cal_incorrect_RT = mean(RT_sec(calIndices & results.Corrects == 0), 'omitnan');
summaryTable.RT_correct_cal(n) = cal_correct_RT;
summaryTable.RT_incorrect_cal(n) = cal_incorrect_RT;
nrf_correct_RT = mean(RT_sec(nrfIndices & results.Corrects == 1), 'omitnan');
nrf_incorrect_RT = mean(RT_sec(nrfIndices & results.Corrects == 0), 'omitnan');
summaryTable.RT_correct_nrf(n) = nrf_correct_RT;
summaryTable.RT_incorrect_nrf(n) = nrf_incorrect_RT;

% average threshold
calrevIndices = (results.Reversal == 1) & (results.WhichCondition == 1);
nrfrevIndices = (results.Reversal == 1) & (results.WhichCondition == 2);
cal_avg_threshold = abs(mean(z_diff(calrevIndices), 'omitnan'));
nrf_avg_threshold = abs(mean(z_diff(nrfrevIndices), 'omitnan'));
summaryTable.threshold_cal(n) = cal_avg_threshold;
summaryTable.threshold_nrf(n) = nrf_avg_threshold;

% self-beliefs
% pre calories
summaryTable.SB_pre_cal(n) = results.pre_sb_cal;

% pre NRF
summaryTable.SB_pre_nrf(n) = results.pre_sb_nrf;

% cols of intermediate self-belief ratings
% Extract Self_belief and WhichCondition data
selfBelief = results.Self_belief;
Conditions = results.WhichCondition;

% Loop through each block to find and assign SB values
for block = 1:nBlocks
    % Find the indices for the current block and condition 1 (cal)
    calIndices = find(Conditions == 1 & selfBelief ~= 0);
    if length(calIndices) >= block
        summaryTable.(['SB_cal_', num2str(block)])(n) = selfBelief(calIndices(block));
    end
    
    % Find the indices for the current block and condition 2 (nrf)
    nrfIndices = find(Conditions == 2 & selfBelief ~= 0);
    if length(nrfIndices) >= block
        summaryTable.(['SB_nrf_', num2str(block)])(n) = selfBelief(nrfIndices(block));
    end

    % Calculate confidence and accuracy per block
    % indices
    % --- Per-block masks 
    blockMask = (results.BlockNumber == block);
    calMask   = (Conditions == 1) & blockMask;
    nrfMask   = (Conditions == 2) & blockMask;

    % --- Accuracy per block ---
    summaryTable.(['acc_cal_block_', num2str(block)])(n) = mean(results.Corrects(calMask), 'omitnan');
    summaryTable.(['acc_nrf_block_', num2str(block)])(n) = mean(results.Corrects(nrfMask), 'omitnan');

    % --- Confidence per block ---
    summaryTable.(['conf_cal_block_', num2str(block)])(n) = mean(results.Confidence(calMask), 'omitnan');
    summaryTable.(['conf_nrf_block_', num2str(block)])(n) = mean(results.Confidence(nrfMask), 'omitnan');
end

% Post SB
% post calories
summaryTable.SB_post_cal(n) = results.post_sb_cal;

% post NRF
summaryTable.SB_post_nrf(n) = results.post_sb_nrf;

%%
%%%%%%%%%% Familiarity and liking %%%%%%%%%%

% Subject number
sID = results.p.subID;

% Stimuli info
items = results.FoodFamiliarity.FoodItem';
names = results.FoodFamiliarity.FoodName';
calories = results.p.list_cal.list_cal_complete(:,4);
nrf = results.p.list_nrf.list_nrf_complete(:,4);
fam = results.FoodFamiliarity.Familiarity';
like = results.FoodLiking.Liking';

% Initial table
init_data = [items, names, fam, like];
init_data = sortrows(init_data);
set_data = [init_data(:,1:2), calories, nrf, init_data(:,3:4)];

% Repeats
reps_cal = num2cell(results.cals_repeat_list)';
reps_nrf = num2cell(results.nrfs_repeat_list)';

% Initialize counters
nStimuli = 285;
occurrences = zeros(nStimuli, 1);
chosen = zeros(nStimuli, 1);

% Condition-specific counters
occurrences_cal = zeros(nStimuli, 1);
chosen_cal = zeros(nStimuli, 1);
occurrences_nrf = zeros(nStimuli, 1);
chosen_nrf = zeros(nStimuli, 1);

% Loop through trials
for i = 1:length(results.Responses)
    pair = results.Pairs{i};
    left = pair(1);
    right = pair(2);
    cond = results.WhichCondition(i); % 1 = cal, 2 = nrf

    % Count occurrences
    occurrences([left, right]) = occurrences([left, right]) + 1;

    % Count chosen
    if results.Responses(i) == 1
        chosen(left) = chosen(left) + 1;
    elseif results.Responses(i) == 2
        chosen(right) = chosen(right) + 1;
    end

    % Condition-specific counts
    if cond == 1
        occurrences_cal([left, right]) = occurrences_cal([left, right]) + 1;
        if results.Responses(i) == 1
            chosen_cal(left) = chosen_cal(left) + 1;
        elseif results.Responses(i) == 2
            chosen_cal(right) = chosen_cal(right) + 1;
        end
    elseif cond == 2
        occurrences_nrf([left, right]) = occurrences_nrf([left, right]) + 1;
        if results.Responses(i) == 1
            chosen_nrf(left) = chosen_nrf(left) + 1;
        elseif results.Responses(i) == 2
            chosen_nrf(right) = chosen_nrf(right) + 1;
        end
    end
end

% Proportion chosen
prop_chosen = chosen ./ occurrences;
prop_chosen(occurrences == 0) = NaN;

prop_chosen_cal = chosen_cal ./ occurrences_cal;
prop_chosen_cal(occurrences_cal == 0) = NaN;

prop_chosen_nrf = chosen_nrf ./ occurrences_nrf;
prop_chosen_nrf(occurrences_nrf == 0) = NaN;

% Correct decisions
corrects = zeros(nStimuli, 1);
correct_counts = zeros(nStimuli, 1);
corrects_cal = zeros(nStimuli, 1);
correct_counts_cal = zeros(nStimuli, 1);
corrects_nrf = zeros(nStimuli, 1);
correct_counts_nrf = zeros(nStimuli, 1);

for i = 1:length(results.Corrects)
    pair = results.Pairs{i};
    left = pair(1);
    right = pair(2);
    cond = results.WhichCondition(i);

    correct_counts([left, right]) = correct_counts([left, right]) + 1;
    if results.Corrects(i) == 1
        corrects([left, right]) = corrects([left, right]) + 1;
    end

    if cond == 1
        correct_counts_cal([left, right]) = correct_counts_cal([left, right]) + 1;
        if results.Corrects(i) == 1
            corrects_cal([left, right]) = corrects_cal([left, right]) + 1;
        end
    elseif cond == 2
        correct_counts_nrf([left, right]) = correct_counts_nrf([left, right]) + 1;
        if results.Corrects(i) == 1
            corrects_nrf([left, right]) = corrects_nrf([left, right]) + 1;
        end
    end
end

% Proportion correct
prop_correct = corrects ./ correct_counts;
prop_correct(correct_counts == 0) = NaN;

prop_correct_cal = corrects_cal ./ correct_counts_cal;
prop_correct_cal(correct_counts_cal == 0) = NaN;

prop_correct_nrf = corrects_nrf ./ correct_counts_nrf;
prop_correct_nrf(correct_counts_nrf == 0) = NaN;

% Confidence
% Initialize confidence accumulators
total_conf = zeros(nStimuli, 1);
conf_counts = zeros(nStimuli, 1);

% Condition-specific confidence
total_conf_cal = zeros(nStimuli, 1);
conf_counts_cal = zeros(nStimuli, 1);
total_conf_nrf = zeros(nStimuli, 1);
conf_counts_nrf = zeros(nStimuli, 1);

% Loop through each trial
for i = 1:length(results.Confidence)
    pair = results.Pairs{i};
    left = pair(1);
    right = pair(2);
    conf = results.Confidence(i);
    cond = results.WhichCondition(i); % 1 = cal, 2 = nrf

    % Add to overall confidence
    total_conf([left, right]) = total_conf([left, right]) + conf;
    conf_counts([left, right]) = conf_counts([left, right]) + 1;

    % Add to condition-specific confidence
    if cond == 1
        total_conf_cal([left, right]) = total_conf_cal([left, right]) + conf;
        conf_counts_cal([left, right]) = conf_counts_cal([left, right]) + 1;
    elseif cond == 2
        total_conf_nrf([left, right]) = total_conf_nrf([left, right]) + conf;
        conf_counts_nrf([left, right]) = conf_counts_nrf([left, right]) + 1;
    end
end

% Calculate average confidence
avg_conf = total_conf ./ conf_counts;
avg_conf(conf_counts == 0) = NaN;

avg_conf_cal = total_conf_cal ./ conf_counts_cal;
avg_conf_cal(conf_counts_cal == 0) = NaN;

avg_conf_nrf = total_conf_nrf ./ conf_counts_nrf;
avg_conf_nrf(conf_counts_nrf == 0) = NaN;


% Convert to cell for table
data = [set_data, ...
    reps_cal, reps_nrf, ...
    num2cell(occurrences), ...
    num2cell(prop_chosen), ...
    num2cell(prop_chosen_cal), ...
    num2cell(prop_chosen_nrf), ...
    num2cell(prop_correct), ...
    num2cell(prop_correct_cal), ...
    num2cell(prop_correct_nrf), ...
    num2cell(avg_conf)...
    num2cell(avg_conf_cal)...
    num2cell(avg_conf_nrf)];

data = cell2table(data);

data.Properties.VariableNames = { ...
    'stim_number', 'stim_name', 'calories', 'nrf','familiarity', 'liking', ...
    'reps_cal', 'reps_nrf', ...
    'occurrence', ...
    'prop_chosen', 'prop_chosen_cal', 'prop_chosen_nrf', ...
    'prop_correct', 'prop_correct_cal', 'prop_correct_nrf', ...
    'average_conf', 'average_conf_cal', 'average_conf_nrf' };

% Add participant ID to the table
sID_col = repmat({sID}, height(data), 1);
data = addvars(data, sID_col, 'Before', 1, 'NewVariableNames', 'sID');
% Concatenate with summary table
ratings_summary = [ratings_summary; data];


%% 
%%%%%%%%%% try ratings analysis %%%%%%%%%%

% select relevant data
% subject number
sID = results.p.subID;
sIDcol = cell2table(repmat({sID}, results.p.totalNumTrial, 1), 'VariableNames', {'sID'});

% item ID
item_left = nan(size(300));
item_right = nan(size(300));

left_row = cellfun(@(x) x(1), results.Pairs);
right_row = cellfun(@(x) x(2), results.Pairs);
for it = 1:length(left_row)
    item_left(it) = results.p.list_cal.list_cal_complete{left_row(it), 5};
    item_right(it) = results.p.list_cal.list_cal_complete{right_row(it), 5};
end

% familiarity & liking
familiarity_left = nan(size(item_left));
familiarity_right = nan(size(item_left));
liking_left = nan(size(item_left));
liking_right = nan(size(item_left));

for t = 1:300
    idx_left = find(cell2mat(results.FoodFamiliarity.FoodItem) == item_left(t));
    idx_right = find(cell2mat(results.FoodFamiliarity.FoodItem) == item_right(t));
    familiarity_left(t) = cell2mat(results.FoodFamiliarity.Familiarity(idx_left(1)));
    familiarity_right(t) = cell2mat(results.FoodFamiliarity.Familiarity(idx_right(1)));
    liking_left(t) = cell2mat(results.FoodLiking.Liking(idx_left));
    liking_right(t) = cell2mat(results.FoodLiking.Liking(idx_right));
end

item_left = array2table(item_left', 'VariableNames', {'item_left'});
item_right = array2table(item_right', 'VariableNames', {'item_right'});
familiarity_left = array2table(familiarity_left', 'VariableNames', {'familiarity_left'});
familiarity_right = array2table(familiarity_right', 'VariableNames', {'familiarity_right'});
liking_left = array2table(liking_left', 'VariableNames', {'liking_left'});
liking_right = array2table(liking_right', 'VariableNames', {'liking_right'});

% put together table
trialratings = [sIDcol, trial, condition, stimdiff, z_stimdiff, response, correct, RT, confidence, item_left, item_right, familiarity_left, familiarity_right, liking_left, liking_right];
excludedRows = find(trialratings.RT < 0.05);
trialratings = trialratings(trialratings.RT > 0.05, :);
trialratings_summary = [trialratings_summary; trialratings];

end


%% Save summary tables
% trial
% (fullfile adds the folder separator; all four files go to Analysis/MetaBites_analysis/Data)
trial_filename = fullfile(post_data_directory, 'MetaBites_triallevel_master.xlsx');
writetable(TrialMaster, trial_filename);

% summary
filename = fullfile(post_data_directory, 'MetaBites_master.xlsx'); % Create the filename
writetable(summaryTable, filename);

% ratings
ratings_filename = fullfile(post_data_directory, 'MetaBites_ratings_master.xlsx');
writetable(ratings_summary, ratings_filename);

% trialratings
filename = fullfile(post_data_directory, 'MetaBites_trialratings.xlsx'); % Create the filename
writetable(trialratings_summary, filename);