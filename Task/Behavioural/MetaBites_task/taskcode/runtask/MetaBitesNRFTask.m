function MetaBitesNRFTask(p, list_nrf_complete, feedback)

results_nrf = struct;

% Create a matrix of all the pairwise differences
nrf = zeros(length(list_nrf_complete), 1);

for v = 1: length(list_nrf_complete)
    nrf(v) = list_nrf_complete{v, 5}; % population is ranked from the most populated to the least
end

for r = 1:length(nrf)
    for c = 1:length(nrf)
        diff_square(r,c) = nrf(r) - nrf(c);
    end
end

% TRIAL LOOP

% Find items in the table matching our difference
stepsize = 5;
differenceTarget = 40; % for example - should be set from staircase on each trial. It should always start as < than nTrial.
results_nrf.S = SetupStaircase(1, differenceTarget, [1 length(list_nrf_complete)], [2,1]);
nreversals = 0;

for n=1:p.nTrials
results_nrf.DifferenceTarget(n) = differenceTarget;
[row, col] = find(diff_square == differenceTarget);

% create vector of suitable pairs

coords = [row, col];

% select random pair from all suitable - could be made more complex
this_pair = coords(randi(length(coords)),:);

% Shuffle the pair, otherwise the highest is always first.
this_pair = Shuffle(this_pair); 


% Trial Loop

[responseNum, correct, scaledX, RT, RT_Conf]=MetaBitesTrialLoop_nrf(p, list_nrf_complete, this_pair, feedback);

% Update staircase
results_nrf.S=StaircaseTrial(1, results_nrf.S, correct);
[results_nrf.S, IsReversal] = UpdateStaircase(1, results_nrf.S, -stepsize);
differenceTarget = results_nrf.S.Signal;
if IsReversal == 1
    nreversals = nreversals + 1;
    results_nrf.i_trial_lastreversal = n;
    results_nrf.Reversal(n) = 1;
else 
    results_nrf.Reversal(n) = 0;
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

results_nrf.Responses(n) = responseNum;
results_nrf.Corrects(n) = correct;
results_nrf.Pairs{n} = this_pair;
results_nrf.Stepsize(n) = stepsize;
results_nrf.NRevelsal = nreversals;
results_nrf.Confidence(n) = scaledX;
results_nrf.RTS(n) = RT;
results_nrf.RT_Confidence(n) = RT_Conf;
end




save(p.filename_nrf, 'results_nrf');

%%%%%%%%%%%%%%%%%% Plot %%%%%%%%%%%%%%%%%%
figure('Name','NRF Staircase');
plot(1:length(results_nrf.DifferenceTarget), results_nrf.DifferenceTarget)
end