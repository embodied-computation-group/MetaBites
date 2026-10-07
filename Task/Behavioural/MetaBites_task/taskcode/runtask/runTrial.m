function [responseNum, correct, scaledX, RT, RT_Conf]=runTrial(p,this_pair, confidence, feedback, condition)
pos_1 = this_pair(1);
pos_2 = this_pair(2);

%loading images and labels
if condition==1
    first_im = strcat('./Food/', p.list_cal.list_cal_complete{pos_1, 2});
    left_image = imread(first_im); im_left = Screen('MakeTexture',p.window, left_image);
    second_im = strcat('./Food/', p.list_cal.list_cal_complete{pos_2, 2});
    right_image = imread(second_im); im_right = Screen('MakeTexture', p.window, right_image);
    
    value_1 = p.list_cal.list_cal_complete(pos_1, 4);
    value_2 = p.list_cal.list_cal_complete(pos_2, 4);
    word_left = p.list_cal.list_cal_complete(pos_1, 1);
    word_right = p.list_cal.list_cal_complete(pos_2, 1);
    stringText = 'Which food has more calories/100g?';
    textColor = p.textColor_cal;

elseif condition==2
    first_im = strcat('./Food/', p.list_nrf.list_nrf_complete{pos_1, 2});
    left_image = imread(first_im); im_left = Screen('MakeTexture',p.window, left_image);
    second_im = strcat('./Food/', p.list_nrf.list_nrf_complete{pos_2, 2});
    right_image = imread(second_im); im_right = Screen('MakeTexture', p.window, right_image);
    
    value_1 = p.list_nrf.list_nrf_complete(pos_1, 4);
    value_2 = p.list_nrf.list_nrf_complete(pos_2, 4);    
    word_left = p.list_nrf.list_nrf_complete(pos_1, 1);
    word_right = p.list_nrf.list_nrf_complete(pos_2, 1);
    stringText = 'Which food has a higher NRF/100g?';
    textColor = p.textColor_nrf;
end
word_left = char(word_left);
word_right = char(word_right);

% Text Position
textRect_left = Screen('TextBounds', p.window, word_left);
textWidth_left = textRect_left(3);
textXpos_left = p.xposition_left - (textWidth_left/3);

textRect_right = Screen('TextBounds', p.window, word_right);
textWidth_right = textRect_right(3);
textXpos_right = p.xposition_right - (textWidth_right/3);

Screen('TextSize',p.window,p.textSize);
DrawFormattedText(p.window, stringText, 'center', 150, textColor);
Screen('FrameRect', p.window, p.gray, p.framePos_left, 50); 
Screen('FrameRect', p.window, p.gray, p.framePos_right, 50); 
Screen('DrawTexture', p.window, im_left, [], p.imPos_left);
Screen('DrawTexture', p.window, im_right, [], p.imPos_right);
Screen('TextSize',p.window,p.countriesTextSize);
DrawFormattedText(p.window, word_left, textXpos_left, p.textYpos, p.textColor);
DrawFormattedText(p.window, word_right,textXpos_right, p.textYpos, p.textColor);

Screen('TextSize',p.window,p.textSize);
DrawFormattedText(p.window, '+', p.xCenter, p.yCenter + 50, p.textColor);
t = Screen(p.window, 'Flip');

FlushEvents;
trialComplete = false;
resp=0;
startTime = GetSecs; % Start time for the decision period
while ~trialComplete
    [k respTime keyCode] = KbCheck();
    if k
        keyPressed = find(keyCode);
        if length(keyPressed) == 1 
            keyName = KbName(keyPressed);
            if strcmp(keyName,'LeftArrow') || strcmp(keyName,'RightArrow')
                trialComplete = true;
                RT = 1000.*(respTime - t);
                resp = keyName;
            elseif strcmp(keyName,'ESCAPE')
                Screen('CloseAll')
                RT = 0;
                return
            end
        end
    end
    if GetSecs - startTime > 4 % Check if 4 seconds have passed
            RT = NaN; % No response time recorded
            resp = 'TooSlow'; % Indicate that the response was too slow
            trialComplete = true;
    end
end


    
if strcmp(resp, 'TooSlow')
    Screen(p.window, 'Flip');
    Screen('TextSize',p.window,p.textSize);  
    DrawFormattedText(p.window, 'You were too slow!', 'center', 'center', [255 0 0]); % Display too slow message
    responseNum = NaN;
    correct = 0;
    scaledX = NaN;
    RT_Conf = NaN;
    Screen(p.window, 'Flip');
    WaitSecs(1.5); % Display the message for 2 seconds
else
    Screen('TextSize',p.window,p.textSize);  
    DrawFormattedText(p.window, stringText, 'center', 150, textColor);
    Screen('FrameRect', p.window, p.gray, p.framePos_left, 50); 
    Screen('FrameRect', p.window, p.gray, p.framePos_right, 50); 
    Screen('DrawTexture', p.window, im_left, [], p.imPos_left);
    Screen('DrawTexture', p.window, im_right, [], p.imPos_right);
    Screen('TextSize',p.window,p.countriesTextSize);
    DrawFormattedText(p.window, word_left, textXpos_left, p.textYpos, p.textColor);
    DrawFormattedText(p.window, word_right, textXpos_right, p.textYpos, p.textColor);

    Screen('TextSize',p.window,p.textSize);
    DrawFormattedText(p.window, '+', p.xCenter, p.yCenter + 50, p.textColor);

    Screen('TextSize',p.window,48);
    if strcmp(resp, 'LeftArrow')
        DrawFormattedText(p.window,'*', p.xCenter - 500, p.yCenter+400, p.textColor);
    elseif strcmp(resp, 'RightArrow')
        DrawFormattedText(p.window,'*', p.xCenter + 500, p.yCenter+400, p.textColor); 
    end
    Screen(p.window, 'Flip');
    WaitSecs(p.Stimtime);

    %% old confidence scale - VAS
    if confidence
        [scaledX, RT_Conf] = Confidence_Scale(p, 0);
        WaitSecs(p.ConfWait);
    else
        scaledX = nan;
        RT_Conf = nan;
    end
    
%% calculate correct
value_1 = value_1{1};
value_2 = value_2{1};
    if strcmp(resp, 'LeftArrow')
        responseNum = 1;
        if value_1 > value_2
            correct = 1;
            WaitSecs(p.RespWait);
        elseif value_1 < value_2
            correct = 0;
            WaitSecs(p.RespWait);
        end
    elseif strcmp(resp, 'RightArrow')
        responseNum = 2;
        if value_1 < value_2
            correct = 1;
            WaitSecs(p.RespWait);
        elseif value_1 > value_2
            correct = 0;
            WaitSecs(p.RespWait);
        end
    end
    
    if feedback ==1
        Screen('TextSize',p.window,p.textSize);
        if responseNum == 1
            if value_1 > value_2
                DrawFormattedText(p.window, 'Correct!', 'center', 'Center', p.textColor);
                Screen(p.window, 'Flip');
                WaitSecs(p.FBWait);
            elseif value_1 < value_2
                DrawFormattedText(p.window, 'Not correct', 'center', 'Center', p.textColor);
                Screen(p.window, 'Flip');
                WaitSecs(p.FBWait);
            end
        elseif responseNum == 2
            if value_1 < value_2
                DrawFormattedText(p.window, 'Correct!', 'center', 'Center', p.textColor);
                Screen(p.window, 'Flip');
                WaitSecs(p.FBWait);
            elseif value_1 > value_2
                DrawFormattedText(p.window, 'Not correct', 'center', 'Center', p.textColor);
                Screen(p.window, 'Flip');
                WaitSecs(p.FBWait);
            end
        end
    end
end
Screen('Close', im_left);
Screen('Close', im_right);
end
