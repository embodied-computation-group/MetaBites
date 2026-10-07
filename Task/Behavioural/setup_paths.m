%% script setup paths
% MUST BE EXECUTE FROM HIGHEST /metacognition_battery

parent_dir = pwd;
function_dir = fullfile(parent_dir, 'functions');
addpath(function_dir);

proj_dir = fileparts(parent_dir);


if IsWin
    MetaBitesdir = [parent_dir '\MetaBites_task\taskcode\runtask\'];
else
    MetaBitesdir = [parent_dir '/MetaBites/taskcode/runtask/'];
end

