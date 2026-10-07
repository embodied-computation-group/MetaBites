function MetaBitesCalTask(p, list_cal_complete, feedback)

results_cal = struct;

% Create a matrix of all the pairwise differences
cal = zeros(length(list_cal_complete), 1);

for v = 1: length(list_cal_complete)
    cal(v) = list_cal_complete{v, 5}; % population is ranked from the most populated to the least
end

for r = 1:length(cal)
    for c = 1:length(cal)
        diff_square(r,c) = cal(r) - cal(c);
    end
end

% TRIAL LOOP

% Find items in the table matching our difference
stepsize = 5;
differenceTarget = 40; % for example - should be set from staircase on each trial. It should always start as < than nTrial.
results_cal.S = SetupStaircase(1, differenceTarget, [1 length(list_cal_complete)], [2,1]);
nreversals = 0;

for n=1:p.nTrials
results_cal.DifferenceTarget(n) = differenceTarget;
[row, col] = find(diff_square == differenceTarget);

% create vector of suitable pairs

coords = [row, col];

% select random pair from all suitable - could be made more complex
this_pair = coords(randi(length(coords)),:);

% Shuffle the pair, otherwise the highest is always first.
this_pair = Shuffle(this_pair); 


% Trial Loop

[responseNum, correct, scaledX, RT, RT_Conf]=MetaBitesTrialLoop_cal(p, list_cal_complete, this_pair, feedback);

% Update staircase
results_cal.S=StaircaseTrial(1, results_cal.S, correct);
[results_cal.S, IsReversal] = UpdateStaircase(1, results_cal.S, -stepsize);
differenceTarget = results_cal.S.Signal;
if IsReversal == 1
    nreversals = nreversals + 1;
    results_cal.i_trial_lastreversal = n;
    results_cal.Reversal(n) = 1;
else 
    results_cal.Reversal(n) = 0;
end


% Adapt stepsize
if nreversals == 4
    stepsize = 2;
elseif nreversals == 8
    stepsize = 1;
end


% list_responses(n) = responseNum;
% list_corrects(n) = correct;
% list_pairs{n} = this_pair;

results_cal.Responses(n) = responseNum;
results_cal.Corrects(n) = correct;
results_cal.Pairs{n} = this_pair;
results_cal.Stepsize(n) = stepsize;
results_cal.NRevelsal = nreversals;
results_cal.Confidence(n) = scaledX;
results_cal.RTS(n) = RT;
results_cal.RT_Confidence(n) = RT_Conf;
end




save(p.filename_cal, 'results_cal');

%%%%%%%%%%%%%%%%%% Plot %%%%%%%%%%%%%%%%%%
figure('Name','Calories Staircase');
plot(1:length(results_cal.DifferenceTarget), results_cal.DifferenceTarget)
end