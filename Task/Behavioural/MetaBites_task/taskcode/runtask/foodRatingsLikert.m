function [results] = foodRatingsLikert(p, results)

lengthList = length(p.list_cal.list_cal_complete);

randomisedList = randperm(lengthList, lengthList);
randomisedList = randomisedList';

% set positions for likert
x_1 = p.screenXpixels * 0.2;
x_2 = p.screenXpixels * 0.4;
x_3 = p.screenXpixels * 0.6;
x_4 = p.screenXpixels * 0.8;

for i = 1:lengthList
    
    position = randomisedList(i);
    
    image_str = strcat('./Food/', p.list_cal.list_cal_complete{position, 2});
    im = imread(image_str); food = Screen('MakeTexture',p.window, im);
    food_name = p.list_cal.list_cal_complete{position, 1};
    item = p.list_cal.list_cal_complete{position, 5};
%% Familiarity    
    
    Screen('TextSize',p.window,p.textSize);
    DrawFormattedText(p.window, 'How familiar are you with this food?', 'center', 150, p.textColor);
% Draw Likert scale labels centered
   Screen('TextSize', p.window, p.textSize_scale);
   DrawFormattedText(p.window, 'Not at all', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_1 - 50, p.scaleY, x_1 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Slightly', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_2 - 50, p.scaleY, x_2 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Moderately', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_3 - 50, p.scaleY, x_3 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Very', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_4 - 50, p.scaleY, x_4 + 50, p.scaleY + 50]);   

    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, '1', x_1, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '2', x_2, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '3', x_3, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '4', x_4, p.scaleY + 50, p.textColor,Inf);
    
    Screen('FrameRect', p.window, p.gray, p.framePos_center, 50);
    Screen('DrawTexture', p.window, food, [], p.imPos_center);
    
    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, food_name, 'center', p.textYPosfam, p.textColor);
    
    t = Screen(p.window, 'Flip');
    
    FlushEvents;
    trialComplete = false;
    while ~trialComplete
        [k respTime keyCode] = KbCheck();
        if strcmp(KbName(keyCode),"1!") | strcmp(KbName(keyCode),"2@") | strcmp(KbName(keyCode),"3#")| strcmp(KbName(keyCode),"4$")
            trialComplete = true;
            
            RT = 1000.*(respTime - t);
        elseif strcmp(KbName(keyCode),'ESCAPE')
            Screen('CloseAll')
            RT = 0;
            return
        end
    end
    
    response = KbName(keyCode);
    
    
    Screen('TextSize',p.window,p.textSize);
    DrawFormattedText(p.window, 'How familiar are you with this food?', 'center', 150, p.textColor);
    % Draw Likert scale labels centered
   Screen('TextSize', p.window, p.textSize_scale);
   DrawFormattedText(p.window, 'Not at all', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_1 - 50, p.scaleY, x_1 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Slightly', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_2 - 50, p.scaleY, x_2 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Moderately', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_3 - 50, p.scaleY, x_3 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Very', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_4 - 50, p.scaleY, x_4 + 50, p.scaleY + 50]);   
   
   
    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, '1', x_1, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '2', x_2, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '3', x_3, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '4', x_4, p.scaleY + 50, p.textColor,Inf);
    
    Screen('FrameRect', p.window, p.gray, p.framePos_center, 50);
    Screen('DrawTexture', p.window, food, [], p.imPos_center);
    
    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, food_name, 'center', p.textYPosfam, p.textColor);
    
    Screen('TextSize',p.window,50);
    if strcmp(response, '1!')
        DrawFormattedText(p.window,'*', x_1, p.scaleY + 100, p.textColor, 2);
        answer = 1;
    elseif strcmp(response, '2@')
        DrawFormattedText(p.window,'*', x_2, p.scaleY + 100, p.textColor, 2);
        answer = 2;
    elseif strcmp(response, '3#')
        DrawFormattedText(p.window,'*', x_3, p.scaleY + 100, p.textColor, 2);
        answer = 3;
    elseif strcmp(response, '4$')
        DrawFormattedText(p.window,'*', x_4, p.scaleY + 100, p.textColor, 2);
        answer = 4;
    end
    Screen(p.window, 'Flip');
    WaitSecs(0.4);

% Save results
    results.FoodFamiliarity.FoodItem{i} = item;
    results.FoodFamiliarity.FoodName{i} = food_name;
    results.FoodFamiliarity.Familiarity{i} = answer;
    results.FoodFamiliarity.RT{i} = RT;
    results.FoodFamiliarity.Type = 'LikertScale';
    

%% Liking    
    
    Screen('TextSize',p.window,p.textSize);
    DrawFormattedText(p.window, 'How much do you like this food?', 'center', 150, p.textColor);
    Screen('TextSize', p.window, p.textSize_scale);
   DrawFormattedText(p.window, 'Strongly dislike', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_1 - 50, p.scaleY, x_1 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Dislike', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_2 - 50, p.scaleY, x_2 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Like', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_3 - 50, p.scaleY, x_3 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Strongly like', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_4 - 50, p.scaleY, x_4 + 50, p.scaleY + 50]);

    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, '1', x_1, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '2', x_2, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '3', x_3, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '4', x_4, p.scaleY + 50, p.textColor,Inf);
    
    Screen('FrameRect', p.window, p.gray, p.framePos_center, 50);
    Screen('DrawTexture', p.window, food, [], p.imPos_center);
    
    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, food_name, 'center', p.textYPosfam, p.textColor);
    
    t = Screen(p.window, 'Flip');
    
    FlushEvents;
    trialComplete = false;
    while ~trialComplete
        [k respTime keyCode] = KbCheck();
        if strcmp(KbName(keyCode),"1!") | strcmp(KbName(keyCode),"2@") | strcmp(KbName(keyCode),"3#")| strcmp(KbName(keyCode),"4$")
            trialComplete = true;
            
            RT = 1000.*(respTime - t);
        elseif strcmp(KbName(keyCode),'ESCAPE')
            Screen('CloseAll')
            RT = 0;
            return
        end
    end
    
    response = KbName(keyCode);
    
    
    Screen('TextSize',p.window,p.textSize);
    DrawFormattedText(p.window, 'How much do you like this food?', 'center', 150, p.textColor);
    Screen('TextSize', p.window, p.textSize_scale);
   DrawFormattedText(p.window, 'Strongly dislike', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_1 - 50, p.scaleY, x_1 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Dislike', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_2 - 50, p.scaleY, x_2 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Like', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_3 - 50, p.scaleY, x_3 + 50, p.scaleY + 50]);
   DrawFormattedText(p.window, 'Strongly like', 'center', p.scaleY, p.textColor, [], [], [], [], [], [x_4 - 50, p.scaleY, x_4 + 50, p.scaleY + 50]);
    
    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, '1', x_1, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '2', x_2, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '3', x_3, p.scaleY + 50, p.textColor,Inf);
    DrawFormattedText(p.window, '4', x_4, p.scaleY + 50, p.textColor,Inf);
    
    Screen('FrameRect', p.window, p.gray, p.framePos_center, 50);
    Screen('DrawTexture', p.window, food, [], p.imPos_center);
    
    Screen('TextSize', p.window, p.textSize_scale);
    DrawFormattedText(p.window, food_name, 'center', p.textYPosfam, p.textColor);
    
    Screen('TextSize',p.window,50);
    if strcmp(response, '1!')
        DrawFormattedText(p.window,'*', x_1, p.scaleY + 100, p.textColor, 2);
        answer = 1;
    elseif strcmp(response, '2@')
        DrawFormattedText(p.window,'*', x_2, p.scaleY + 100, p.textColor, 2);
        answer = 2;
    elseif strcmp(response, '3#')
        DrawFormattedText(p.window,'*', x_3, p.scaleY + 100, p.textColor, 2);
        answer = 3;
    elseif strcmp(response, '4$')
        DrawFormattedText(p.window,'*', x_4, p.scaleY + 100, p.textColor, 2);
        answer = 4;
    end
    Screen(p.window, 'Flip');
    WaitSecs(0.4);

% Save results
    results.FoodFamiliarity.FoodItem{i} = item;
    results.FoodFamiliarity.FoodName{i} = food_name;
    results.FoodLiking.Liking{i} = answer;
    results.FoodLiking.RT{i} = RT;
    results.FoodLiking.Type = 'LikertScale';

    if i == 150
        string = ['Halfway through part 1'];
        DrawFormattedText(p.window,[string '\n \n Press SPACE to continue'], 'center', 'center', p.textColor);
        Screen('Flip', p.window);
        KbStrokeWait;
    
        WaitSecs(.5);
    end
    
end
Screen('Close', food);

end