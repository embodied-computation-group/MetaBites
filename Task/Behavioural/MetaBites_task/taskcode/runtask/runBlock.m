function [results, trial_counter] = runBlock(p,confidence, self_beliefs, feedback, blockNumber, results, trial_counter)
%% function to run one block of the MetaBites task.


%% Set up staircases for each condition

nreversals = results.nreversals; % n columns per conditions
step_level = results.step_level;


%% Vector with list of conditions
% Initialize the condition vector
condition_vector = zeros(p.totalNumTrial, 1);

% Populate the condition vector for each block
for block = 1:p.numberOfBlocks
    % Create a block with 30 trials of each condition
    block_vector = [ones(p.trialsPerCondit, 1); ones(p.trialsPerCondit, 1) * 2];
    
    % Randomly shuffle the order of the two halves
    if rand > 0.5
        block_vector = [block_vector(p.trialsPerCondit + 1:end); block_vector(1:p.trialsPerCondit)];
    end
    
        % Randomly decide which condition starts the block
    if rand > 0.5
        block_vector = flip(block_vector);
    end
    
    % Assign the block vector to the appropriate section of the condition vector
    startIdx = (block - 1) * p.trialsPerBlock + 1;
    endIdx = block * p.trialsPerBlock;
    condition_vector(startIdx:endIdx) = block_vector;
end

results.ConditionVectors = condition_vector';

%%
results.condition_counter = [0 0];

%% run the block

for n=1:p.trialsPerBlock
    trial_counter = trial_counter + 1;
    
    %% initialize trial parameters
    condition = results.ConditionVectors(trial_counter); % 1=cals, 2=nrfs
    differenceTarget = results.S(condition).Signal;
    this_stepsize = results.stepsize(condition, step_level(condition));
    
 
    if condition == 1
        results.condition_counter(1) = results.condition_counter(1)+1;
    
    else
        
        results.condition_counter(2) = results.condition_counter(2)+1;
        
    end
    
    [this_pair, results] = find_difference_pair(condition, differenceTarget, p, results, trial_counter);
    
    %% exception to slightly randomize difference target is the same as the last trial
    
    if results.condition_counter(1) > 1 && results.condition_counter(2) > 1 
        
        if  this_pair == results.last_pair{condition}
            
            % increment the step level slightly by the medium amount 
            differenceTarget = differenceTarget + p.stepsize(condition, 2)*sign(randn(1,1)); 
            
            [this_pair, results] = find_difference_pair(condition, differenceTarget, p, results, trial_counter);
            
        end
        
    end
        
   
    
    %% check if the stimulus has been used more than some threshold, if so randomize 
    
    
    if condition == 1
        
        %keep pseudo-randomly incrementing until a non-repeat is found
        while results.cals_repeat_list(this_pair(1)) > results.repeat_threshold ...
                || results.cals_repeat_list(this_pair(2)) > results.repeat_threshold
            
            differenceTarget = differenceTarget + p.stepsize(condition, 2)*sign(randn(1,1));
            [this_pair, results] = find_difference_pair(condition, differenceTarget, p, results, trial_counter);
            
        end
        
    elseif condition == 2
        
        while results.nrfs_repeat_list(this_pair(1)) > results.repeat_threshold ...
                || results.nrfs_repeat_list(this_pair(2)) > results.repeat_threshold
            
            differenceTarget = differenceTarget + p.stepsize(condition, 2)*sign(randn(1,1));
            [this_pair, results] = find_difference_pair(condition, differenceTarget, p, results, trial_counter);      
        end  
    end
    
        
    
    
    
    %% update stimuli counters
    
    if condition == 1
    
    results.cals_repeat_list(this_pair(1)) =  results.cals_repeat_list(this_pair(1))+1;
    results.cals_repeat_list(this_pair(2)) =  results.cals_repeat_list(this_pair(2))+1;
   
    elseif condition == 2
        
    results.nrfs_repeat_list(this_pair(1)) = results.nrfs_repeat_list(this_pair(1))+1;
    results.nrfs_repeat_list(this_pair(2)) = results.nrfs_repeat_list(this_pair(2))+1;   
    
    end
    
    
    
    %% log the last pair
      
    results.last_pair{condition} = this_pair;   
    
    
    %% Shuffle the pair, otherwise the highest is always first.
    this_pair = Shuffle(this_pair);
    
    
    %% Trial
    
    [responseNum, correct, scaledX, RT, RT_Conf] = runTrial(p, this_pair, confidence, feedback, condition);
    
    
    
    %% Update staircase
    results.S(condition)=StaircaseTrial(1, results.S(condition), correct);
    [results.S(condition), IsReversal] = UpdateStaircase(1, results.S(condition), -this_stepsize);
    differenceTarget = results.S(condition).Signal;
    
    
    if IsReversal == 1
        nreversals(condition) = nreversals(condition) + 1;
        results.Reversal(trial_counter) = 1;
    
    else
        
        results.Reversal(trial_counter) = 0;
    
    end
    
    
    %% Adapt stepsize
    
    if nreversals(condition) == 4
        
        step_level(condition) = 1;
        %this_stepsize = results.stepsize(condition, step_level(condition));
        
    elseif nreversals(condition) == 8
        
        step_level(condition) = 2;
       % this_stepsize = results.stepsize(condition, step_level(condition));
        
   elseif nreversals(condition) == 16
        
       step_level(condition) = 3;
     %   this_stepsize = results.Stepsize(condition, step_level(condition));
        
    end
    
%% insert self beliefs with trial counter

    % Check if the trial is at the halfway point of the block
    if mod(trial_counter, p.trialsPerBlock) == p.trialsPerCondit
        % Call the self_belief function at the halfway point
        [scaledSB, RT_SB] = self_belief(p, condition);
    % Check if the trial is at the end of the block
    elseif mod(trial_counter, p.trialsPerBlock) == 0
        % Call the self_belief function at the end of the block
        [scaledSB, RT_SB] = self_belief(p, condition);
    else
        scaledSB = 0;
        RT_SB = 0;
    end
 
    
    %% update and save results
    results.trial(trial_counter) = trial_counter;
    results.Responses(trial_counter) = responseNum;
    results.Corrects(trial_counter) = correct;
    results.Pairs{trial_counter} = this_pair;
    results.this_stepsize(trial_counter) = this_stepsize;
    results.nreversals = nreversals;
    results.RTS(trial_counter) = RT;
    results.BlockNumber(trial_counter) = blockNumber;
    results.WhichCondition(trial_counter) = condition;
    results.DifferenceTarget(trial_counter) = differenceTarget;
    results.step_level = step_level;
    results.p = p; 
    
    if confidence
        results.Confidence(trial_counter) = scaledX;
        results.RT_Confidence(trial_counter) = RT_Conf;
    end

    %% insert save self-beliefs
    if self_beliefs
        results.Self_belief(trial_counter) = scaledSB;
        results.RT_Self_belief(trial_counter) = RT_SB;
    end


    % update and save
    results.p = p; 
end
end