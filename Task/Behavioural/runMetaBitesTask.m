function out = runMetaBitesTask(sID)
%% run the MetaBites task

clear all

setup_paths;

if nargin < 1
    sID = inputdlg('Please Enter the sID');
    sID = sID{:};
end

clc
fprintf('%%%%\n\n %%%% RUNNING MetaBites TASK\n\n%%%%')

% Add MetaBites paths
addpath(genpath(MetaBitesdir))

% Change to task directory
cd(MetaBitesdir)

% Execute task
MetaBiteswrapper(sID)

% Return to parent directory and clean path
cd(parent_dir)
rmpath(genpath(MetaBitesdir))

%% Copy data to export directory (OVERWRITES DATA)
setup_paths
cd(parent_dir)

datfiles = subdir(fullfile('*Data*mat'));

for n = 1:length(datfiles)
    copyfile(datfiles(n).name, fullfile(proj_dir, 'all_data'), 'f')
end
end