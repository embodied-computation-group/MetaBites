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
subject_ids = [3003 3006:3010 3012:3034 3036:3038]; % all subject IDs to be analysed now
subj_prefix = 'MetaBitesData_';
% numbers for table allocation
nSubjects = length(subject_ids);
nTrials = 300;
nBlocks = 5;

%% allocate and start summary table
% Define the fixed columns
% Define the fixed columns
%columns = {'sid', 'condition', 'trial', 'signal', 'response', 'correct', 'confidence'};

% Create an empty table with the specified columns
metadtable = table(); %array2table(nan((nSubjects*nTrials), length(columns)), 'VariableNames', columns);

%% load in files

for n = 1:nSubjects
    
% file path per subject
subject_data_file = [pre_data_directory '\' subj_prefix int2str(subject_ids(n)) '.mat']; 
% load in results struct
load(subject_data_file)

%% get relevant trial level data

% select relevant data
sid = repmat(subject_ids(n), nTrials, 1);

% condition 
condition = results.WhichCondition';
condition = replace(string(condition), {'1', '2'}, {'calories', 'nrf'});
% trial
trials = results.trial';
% response
response = results.Responses';
response = response -1;
% correct
corrects = results.Corrects';
% confidence
confidence = results.Confidence';
% binned confidence
edges = linspace(1, 100, 6);
binnedconf = discretize(results.Confidence, edges)';
% signal
signal = response;  % Initialize signal as response
signal(corrects == 0) = 1 - response(corrects == 0);  % Flip response if incorrect

% put together table
temp_table = table(sid, condition, trials, signal, response, corrects, confidence, binnedconf, ...
                       'VariableNames', {'sid', 'condition', 'trial', 'signal', 'response', 'correct', 'confidence', 'binnedconfidence'});
    
% Discard trials with RT < 50 ms and trials without a response,
% using the same rule as mat2excel.m
RT_sec = round(results.RTS' / 1000, 4);
temp_table = temp_table(RT_sec > 0.05, :);

% Append the temporary table to the main table
metadtable = [metadtable; temp_table];


end

% Define the filename for the saved table
filename = 'Meta-d_data.xlsx';

% Combine the directory and filename to create the full file path
full_file_path = fullfile(post_data_directory, filename);

% Write the data to an Excel file with the dynamic filename
writetable(metadtable, full_file_path);