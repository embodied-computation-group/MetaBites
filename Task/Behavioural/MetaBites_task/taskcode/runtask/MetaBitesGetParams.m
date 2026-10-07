function p = MetaBitesGetParams(inArg)
% Params for MetaBites metacognition task
% GM 2019

%% Load Mat files

%p.list_countries = load('list_countries_complete.mat');
p.list_cal = load('list_cal_complete.mat');
p.list_nrf = load('list_nrf_complete.mat');

%%  Subject Parameters

if nargin < 1
    
    p.subID = inputdlg('Please Enter SubjectID', 'SubjectID');
    
    
else
    p.subID = inArg;

end

p.filename = ['MetaBitesData_' p.subID '.mat'];
p.filename_ratings = ['ratings_backup_' p.subID '.mat'];
p.filename_block = ['block_backup_' p.subID '.mat'];

if IsWin
    dataDir = [pwd '\Data\'];
    backupDir = [pwd '\Data\Backup\'];
else
    dataDir = [pwd '/Data/'];
    backupDir = [pwd '/Data/Backup/'];
end

if ~exist('Data')
    mkdir Data
end
if ~exist('Backup')
    mkdir Backup
end

p.filename = [dataDir p.filename];
p.backup_ratings = [backupDir p.filename_ratings];
p.backup_block = [backupDir p.filename_block];

%% instruction texts

p.instruction_text{1} = ['This experiment consists of two parts.\n', ...
                      ' \n\n'...
                      ' In the first part, you will see many plates containing different kinds of food. \n\n'...
                      ' These foods will be your choice options in part two.\n\n\n'...
                      '\n\n Press SPACE to continue.\n\n']; 

p.instruction_text{2} = ['During this first part, you will answer two questions about each food: \n\n\n'...
                      ' How familiar you are with this food, and\n\n'...
                      ' how much you prefer/like this food.  \n\n\n'...
                      ' You will answer this with the number  1 2 3 4  keys. \n\n'... 
                      '\n\n Press SPACE to continue.\n\n'];

p.instruction_text{3} = [' Please let the experimenter know if you have any questions.\n\n' ...
                      ' Otherwise you are free to continue to the first part of the experiment.\n\n' ...
                      ' \n\nPress SPACE to continue to the task.\n\n'];


p.task_text{1} = ['This concludes the first part of the experiment.\n\n' ...
                  ' \n\nPress SPACE to continue.\n\n'];

p.task_text{2} = ['In the second part of this experiment you will make choices about the different foods you just saw.\n\n', ...
                      ' \n'...
                      ' On each trial you will see two plates of food. \n\n'...
                      ' With the left and right arrow keys, \n\n'...
                      ' you have to decide which has more calories or a higher NRF.\n\n\n'...
                      ' You have 4 seconds to make your decision. \n\n'...                      
                      '\n\n Press SPACE to continue.\n\n']; 

p.task_text{3} = [' For one topic you will be judging which food has a higher calorie content,\n\n'...
                      ' calories are a measurement of energy that food provides to the body, measured by cals/100g.\n\n'...
                      ' \n\n '...
                      ' For the other you will be judging which food has a higher Nutrient Rich Foods Index (NRF).\n\n'...
                      ' The NRF Index is a measurement of how nutritious food is, measured by NRF/100g. \n\n '...
                      ' \n'...
                      ' NRF considers the amount of important nutrients (protein, fiber, vitamins) that are good for your body, \n\n'...
                      ' while also considering less healthy components (added sugar, unhealthy fats). \n\n'... 
                      ' A higher NRF score means the food provides more nutrients your body needs and less that should limit.\n\n' ...
                      '\n\n Press SPACE to continue.\n\n'];
                      
p.task_text{4} = [' After each decision, as quickly and accurately as possible, \n\n'...
                      ' you will rate how confident you are that your decision was correct. \n\n\n'...
                      ' You make your decision using the left and right arrow keys and confirm with the space bar. \n\n\n'...
                      ' Before the task, after the task, and after each block of questions, \n\n'...
                      ' you will be asked how well you think you are performing in general for a certain topic.\n\n\n' ...
                      ' For both of these ratings, you should try to use the entire width of the confidence scale.\n\n ' ...
                      ' \n\n Press SPACE to continue.\n\n'];
              
p.task_text{5} = ['We will begin with a short practice round so you can understand how to make your responses.\n\n', ...
                      ' After the practice, please let the experimenter know if you have any questions about the task.\n\n' ...
                      ' \n\nPress SPACE to continue to the practice.\n\n'];


%% Windows parameters
p.gray = [127 127 127 ]; 
p.white = [255 255 255]; 
p.black = [0 0 0];
p.red = [250 0 0]; 
p.blue = [50 0 250];
p.green = [0 204 0]; 
p.orange = [255 128 0];
p.col_cal = p.orange;
p.col_nrf = p.green;
p.bgcolor = p.black;
p.textColor = p.white;
p.textColor_cal = p.col_cal;
p.textColor_nrf = p.col_nrf;
p.textSize = 64; 
p.textSize_scale = 40; 
p.countriesTextSize = 24;

%p.screensize = [0 0 2000 2000];
p.screensize = [];

p.screenNum = 0;

%PsychDebugWindowConfiguration(0, 0.5)
Screen('Preference', 'SkipSyncTests', 0);
[p.window, p.rect] = Screen('OpenWindow', p.screenNum, p.black, p.screensize);
Screen('FillRect', p.window, p.bgcolor);
[p.xCenter, p.yCenter] = RectCenter(p.rect);
[p.screenXpixels, p.screenYpixels] = Screen('WindowSize', p.window);

%[p.screenXpixels, p.screenYpixels] = Screen('WindowSize', [0 0 500 500]);
% Screen(p.window, 'Flip');

%% Task Parameters
p.totalNumPracticeTrial = 20; %20
% Number of conditions
p.nConditions = 2;

% Number of blocks
p.numberOfBlocks = 5; %5

%Number of trials per block per condition, the total number of trials will be (p.trialsPerCondit * p.nConditions * p.numberOfBlocks)
p.trialsPerCondit = 30; %30

p.trialsPerBlock = p.trialsPerCondit * p.nConditions;

p.totalNumTrial = p.trialsPerBlock * p.numberOfBlocks;


%% trial timings

p.Stimtime = 0.25;
p.ConfWait = 0.25;
p.RespWait = 0.25;
p.FBWait = 0.25 ;

%% staircase parameters

% condition 1 stepsizes
p.stepsize(1,1) = 100; % calories
p.stepsize(1,2) = 50;
p.stepsize(1,3) = 25; 

% condition 2 stepsizes
p.stepsize(2,1) = 75; % NRF
p.stepsize(2,2) = 50;
p.stepsize(2,3) = 25; 


%p.countries_srange = [0.1 5];
p.cal_srange = [1 500];
p.nrf_srange = [1 300];

%p.thisDifferenceTarget_gdp = 1; % initial difference target
p.thisDifferenceTarget_calories = 150; % initial difference target
p.thisDifferenceTarget_nrfs = 200; % initial difference target


%p.S(1) = SetupStaircase(1, [p.thisDifferenceTarget_gdp], p.countries_srange, [2,1]);
p.S(1) = SetupStaircase(1, [p.thisDifferenceTarget_calories], p.cal_srange, [2,1]);
p.S(2) = SetupStaircase(1, [p.thisDifferenceTarget_nrfs], p.nrf_srange, [2,1]);

%% countries Image and Text parameters

p.xposition_left = p.screenXpixels * .25;
p.xposition_right = p.screenXpixels * .75;
p.scaleY = p.screenYpixels * 0.83; 

% Set scaling
scaling_side = 500;  % For left and right images
scaling_center = 275; % For center image

% Image Position
imBase_side = [0 0 300+scaling_side 200+scaling_side];
imBase_center = [0 0 300+scaling_center 200+scaling_center];

p.imPos_left = CenterRectOnPointd(imBase_side, p.xposition_left, p.screenYpixels/2);
p.imPos_right = CenterRectOnPointd(imBase_side, p.xposition_right, p.screenYpixels/2);
p.imPos_center = CenterRectOnPointd(imBase_center, p.screenXpixels/2, p.screenYpixels/2 - 60);

% Frame Position
frameBase_side = [0 0 305+scaling_side 205+scaling_side];
frameBase_center = [0 0 305+scaling_center 205+scaling_center];

p.framePos_left = CenterRectOnPointd(frameBase_side, p.xposition_left, p.screenYpixels/2);
p.framePos_right = CenterRectOnPointd(frameBase_side, p.xposition_right, p.screenYpixels/2);
p.framePos_center = CenterRectOnPointd(frameBase_center, p.screenXpixels/2, p.screenYpixels/2 - 60);


% Text Position

% p.textXpos_left = p.screenXpixels * .15;
% p.textXpos_right = p.screenXpixels * .70;

%p.textYpos = p.yCenter + 200;


p.textYpos = p.yCenter + 400;



p.textYPosfam = p.yCenter + 250;



%% for discrete confidence scale

[p.mx,p.my] = RectCenter(p.rect);
p.sittingDist = 40;

% confidence scale
p.stim.scaleType = 'continuous'; % discrete or continuous
p.stim.VASwidth_inDegrees = 15;
p.stim.VASheight_inDegrees = 2;
p.stim.VASoffset_inDegrees = 0;
p.stim.arrowWidth_inDegrees = 0.5;

p.stim.VASwidth_inPixels = degrees2pixels(p.stim.VASwidth_inDegrees, p.sittingDist);
p.stim.VASheight_inPixels = degrees2pixels(p.stim.VASheight_inDegrees, p.sittingDist);
p.stim.VASoffset_inPixels = degrees2pixels(p.stim.VASoffset_inDegrees, p.sittingDist);
p.stim.arrowWidth_inPixels = degrees2pixels(p.stim.arrowWidth_inDegrees, p.sittingDist);

p.times.confDuration_inSecs = 4;
p.times.confFBDuration_inSecs = 0.250;

%% Create a matrix of all the pairwise differences
p.diff_square = cell(2,1);

% Food  



%%


% countries
% 
% Create a matrix of all the pairwise differences - RANK FROM ORDER
%gdp = log(p.list_countries.numList);
%diff_square = [];
%
%for r = 1:length(gdp)
%    for c = 1:length(gdp)
%        diff_square(r,c) = gdp(r) - gdp(c);
%    end
%end

%p.diff_square{1}=round(diff_square, 3, 'significant'); 

%% calories

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

%% initialize usage counters for all stimuli

%p.countries_repeat_list = zeros(1,length(gdp));
p.cals_repeat_list = zeros(1,length(calories));
p.nrfs_repeat_list = zeros(1,length(nrfs));
p.repeat_threshold = 4;


end