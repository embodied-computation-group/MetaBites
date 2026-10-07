function [pre_sb_cal, pre_sb_nrf] = pre_self_belief(p)

% Common settings
KbName('UnifyKeyNames');
escKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
respKey = KbName('Space');
pixelsPerPress = 5;
lineWidth = 4;
buttomLine = p.yCenter;
startLine = p.xCenter - 500;
endLine = p.xCenter + 500;

% Function to display question and get response
function response = get_response(textLine, dotColor)
    %initialDotPos = p.xCenter;
    % Calculate jitter range (10% of the line length)
    jitterRange = 0.1 * (endLine - startLine);

    % Add jitter to the initial dot position
    initialDotPos = p.xCenter + randi([-jitterRange, jitterRange]);
    dotX = initialDotPos;
    confirmed = false;
    while 1
        % Display text
        Screen('TextSize', p.window, 40);
        DrawFormattedText(p.window, textLine, 'center', p.yCenter - 250, p.white);
        
        % Draw static line
        Screen('DrawLine', p.window, p.white, startLine, buttomLine, endLine, buttomLine, lineWidth);
        Screen('DrawLine', p.window, p.white, startLine, buttomLine - 10, startLine, buttomLine + 10, lineWidth);
        Screen('DrawLine', p.window, p.white, endLine, buttomLine - 10, endLine, buttomLine + 10, lineWidth);
        Screen('DrawLine', p.window, p.white, p.xCenter, buttomLine - 10, p.xCenter, buttomLine + 10, lineWidth);
        
        % Display bottom text
        Screen('TextSize', p.window, 30);
        DrawFormattedText(p.window, '0% correct', p.xCenter - 560, buttomLine + 60, p.white);
        DrawFormattedText(p.window, '100% correct', p.xCenter + 470, buttomLine + 60, p.white);
        
        % Check for key press
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyCode(leftKey)
            dotX = dotX - pixelsPerPress;
        elseif keyCode(rightKey)
            dotX = dotX + pixelsPerPress;
        end
        if dotX < startLine
            dotX = startLine;
        elseif dotX > endLine
            dotX = endLine;
        end
        
        % Draw the dot
        if confirmed
            Screen('DrawDots', p.window, [dotX buttomLine], 20, p.green, [], 2);
        else
            Screen('DrawDots', p.window, [dotX buttomLine], 20, p.orange, [], 2);
        end
        
        % Flip screen
        Screen('Flip', p.window);
        
        % Check for response key
        if keyIsDown
            if keyCode(respKey)
                if confirmed
                    response = fix(mapfun(dotX, startLine, endLine, 1, 100));
                    break;
                else
                    confirmed = true;
                end
            elseif keyCode(escKey)
                ShowCursor;
                Screen('CloseAll');
                return;
            end
        end
    end
end

% Get responses for both questions
pre_sb_cal = get_response('How well do you think you are going to do on the calorie trials? (average correct answers)', p.orange);

% Pause to ensure the second question is displayed properly
WaitSecs(1);

pre_sb_nrf = get_response('How well do you think you are going to do on the NRF trials? (average correct answers)', p.green);

end