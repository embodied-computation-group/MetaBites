clc
clear all 
%% Make nutrient lists

% Define the file paths
parent_dir = pwd; % task directory
excelFilePath = 'MetaBites_task/stimuli/food/F4H_Collection_n377_food pictures_nutrient_info_vdec18.xlsx';
calListPath = 'MetaBites_task/taskcode/runtask/list_cal_complete.mat';
nrfListPath = 'MetaBites_task/taskcode/runtask/list_nrf_complete.mat';
post_data_directory = [parent_dir '\Behavioural\Data\'];

%% CLOSE THE EXCEL FILE
% Load the Excel file using readtable without headers from the second sheet
opts = detectImportOptions(excelFilePath, 'Sheet', 2, 'Range','A:P', 'NumHeaderLines', 0);
data = readtable(excelFilePath, opts);

% Select relevant data
data = data(:, [1, 2, 3, 16]);
data.Properties.VariableNames = {'ImageNr', 'FoodName', 'Calories', 'NRF'};

% Remove rows with NaN values
data = rmmissing(data);

% Extract relevant columns from the table
image_numbers = data.ImageNr; % Column A (image numbers)
food_names = data.FoodName; % Column B (food names)
calories = data.Calories; % Column C (calories per 100g)
nrf = data.NRF; % Column P (NRF per 100g)

% Initialize the complete lists
list_cal_complete = cell(size(data, 1), 5);
list_nrf_complete = cell(size(data, 1), 5);

% Populate the lists
for i = 1:size(data, 1)
    image_file_name = sprintf('%d.jpg', image_numbers(i));
    
    % For calories list
    list_cal_complete{i, 1} = food_names{i};
    list_cal_complete{i, 2} = image_file_name;
    list_cal_complete{i, 3} = [];
    list_cal_complete{i, 4} = calories(i);
    list_cal_complete{i, 5} = image_numbers(i);
    
    % For NRF list
    list_nrf_complete{i, 1} = food_names{i};
    list_nrf_complete{i, 2} = image_file_name;
    list_nrf_complete{i, 3} = [];
    list_nrf_complete{i, 4} = nrf(i);
    list_nrf_complete{i, 5} = image_numbers(i);
end


% Save the lists to the specified paths
save(calListPath, 'list_cal_complete');
save(nrfListPath, 'list_nrf_complete');

% make data frames for export
stim_table = table(image_numbers, food_names, calories, nrf,...
                       'VariableNames', {'image', 'food', 'calories', 'nrf'});
filename = [post_data_directory, 'stim_data.xlsx']; % Create the filename

% Write the data to an Excel file with the dynamic filename
writetable(stim_table, filename);