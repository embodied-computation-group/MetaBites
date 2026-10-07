 %%%%%%%%%%%%%%%%%%%MetaBitesMETACOGNITIONTASK%%%%%%%%%%%% %%%%%%%% %%%%%%% %

 function out = MetaBitesWrapper(sID)
 
KbName ('UnifyKeyNames');  
KbCheck;

p = MetaBitesGetParams(sID); 
Screen('TextFont',p.window,'Helvetica'); 
Screen('TextSize', p.window, p.textSize);
HideCursor;


% Introduction
DrawFormattedText(p.window,['Welcome to the experiment!' '\n \n Press SPACE to continue'], 'center', 'center', p.textColor);
Screen('Flip', p.window);
WaitSecs(.5);
KbWait;

%% ratings
results = struct;
MetaBites_instructions(p.window, p.instruction_text);

likert = 1; % 0 == YES/NO questions; 1 == likert scale 
[results]=foodRatings(p, results, likert);

save(p.backup_ratings, 'results');

%% initialize a dummy results
results.S(1) = p.S(1); % condition 1 staircase 
results.S(2) = p.S(2); % condition 2 staircase

results.nreversals = [0 0]; % n columns per conditions 
results.step_level = [1 1]; % step levels for each condition
results.stepsize = p.stepsize; 

results.cals_repeat_list = p.cals_repeat_list;
results.nrfs_repeat_list = p.nrfs_repeat_list;
results.repeat_threshold = p.repeat_threshold;


%% practice block
feedback = 1;
confidence =  1; 
enablePlotting = 1; 
trial_counter = 0; 
WaitSecs(1);
blockNumber = 1;
MetaBites_instructions(p.window, p.task_text);

[results, trial_counter] = runPracticeBlock(p,confidence, feedback, blockNumber, results, trial_counter);


DrawFormattedText(p.window,['Great! Please ask the experimenter if you have any questions.'...
                            '\n \n Otherwise, press SPACE to continue'], 'center', 'center', p.textColor);
Screen('Flip', p.window);
WaitSecs(.5);
KbWait;

%% initialize a real results

results.S(1) = p.S(1); % condition 1 staircase 
results.S(2) = p.S(2); % condition 2 staircase

results.nreversals = [0 0]; % n columns per conditions 
results.step_level = [1 1]; % step levels for each condition
results.stepsize = p.stepsize; 


%results.countries_repeat_list = p.countries_repeat_list;
results.cals_repeat_list = p.cals_repeat_list;
results.nrfs_repeat_list = p.nrfs_repeat_list;
results.repeat_threshold = p.repeat_threshold;


%% Real Block
feedback = 0;
confidence =  1; 
self_beliefs = 1;
enablePlotting = 1; 
trial_counter = 0; 
WaitSecs(1);

%% insert pre-self beliefs
[pre_sb_cal, pre_sb_nrf] = pre_self_belief(p);

%% run blocks
for blockNumber = 1 : p.numberOfBlocks
   
    [results, trial_counter] = runBlock(p,confidence, self_beliefs, feedback, blockNumber, results, trial_counter);
    save(p.backup_block, 'results');
%break    
    string = ['End of block ', num2str(blockNumber), ' out of ', num2str(p.numberOfBlocks)];
    DrawFormattedText(p.window,[string '\n \n Press SPACE to continue'], 'center', 'center', p.textColor);
    Screen('Flip', p.window);
    KbStrokeWait;
    
    WaitSecs(.5);
    
end


%% insert post-self beliefs
[post_sb_cal, post_sb_nrf] = post_self_belief(p);


%% Save results
results.pre_sb_cal = pre_sb_cal;
results.pre_sb_nrf = pre_sb_nrf;
results.post_sb_cal = post_sb_cal;
results.post_sb_nrf = post_sb_nrf;

save(p.filename, 'results');

%% End
Screen('TextSize', p.window, p.textSize);
DrawFormattedText(p.window,['The experiment is finished!' '\n \n Thank you for participating.'], 'center', 'center', p.textColor);
Screen('Flip', p.window);
WaitSecs(2);

sca;       

out = [];

 end









 