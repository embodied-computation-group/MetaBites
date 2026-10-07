function [scaledSB, RT_SB] = self_belief(p, condition)
KbName('UnifyKeyNames');
escKey = KbName('ESCAPE');

% Define response keys 
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
respKey = KbName('Space');

% Set the amount we want our square to move on each button pr ess
pixelsPerPress = 5;

% Line
buttomLine = p.yCenter;
lineWidth = 4;
startLine = p.xCenter - 500;
endLine = p.xCenter + 500;


% initialDotPos = randi([startLine, endLine]); 
%initialDotPos = p.xCenter;

% Calculate jitter range (10% of the line length)
jitterRange = 0.1 * (endLine - startLine);

% Add jitter to the initial dot position
initialDotPos = p.xCenter + randi([-jitterRange, jitterRange]);
dotX = initialDotPos;

while 1
    
% Text - top of the screen
if condition==1
textLine =  ['How well do you think you are doing on the calories trials? (average correct answers)'];
elseif condition==2
textLine =  ['How well do you think you are doing on the NRF trials? (average correct answers)'];
end
   
Screen('TextSize',p.window,40);    
DrawFormattedText(p.window,textLine,'center',p.yCenter - 250,p.white);


% Static line - bottom
Screen('DrawLine', p.window, p.white, startLine , buttomLine, p.xCenter + 500, buttomLine, lineWidth);
Screen('DrawLine', p.window, p.white, startLine, buttomLine - 10, startLine, buttomLine + 10, lineWidth);
Screen('DrawLine', p.window, p.white, endLine, buttomLine - 10, endLine, buttomLine + 10, lineWidth);
Screen('DrawLine', p.window, p.white, p.xCenter, buttomLine - 10, p.xCenter, buttomLine + 10, lineWidth);

Screen('TextSize',p.window,30);
% Text - bottom
DrawFormattedText(p.window,'0% correct',p.xCenter - 560,buttomLine + 60,p.white);
% DrawFormattedText(p.window,'50% con','center',buttomLine + 60,p.white);
DrawFormattedText(p.window,'100% correct',p.xCenter + 470,buttomLine + 60,p.white);


[keyIsDown, respSecs, keyCode] = KbCheck;

% responses (keyCode)
if keyCode(leftKey)
    dotX = dotX -  pixelsPerPress;
elseif keyCode(rightKey)
    dotX = dotX + pixelsPerPress;
end

if dotX < startLine     % do not move outside the limit
    dotX = startLine;    % keep it at the limit!
elseif dotX > endLine
    dotX = endLine;
end


% draw the dot
Screen('DrawDots', p.window, [dotX buttomLine], 20, p.orange, [], 2);

scaledSB = mapfun(dotX, startLine, endLine, 1, 100);
scaledSB = fix(scaledSB);

% scaledXstr = num2str(scaledX);
% DrawFormattedText(p.window,scaledXstr,p.xCenter - 20,buttomLine + 260,p.white);

t=Screen(p.window,'Flip');



FlushEvents;
[keyIsDown, sec, keyCode] = KbCheck;


if keyIsDown
    if keyCode(respKey)
%         endTime = GetSecs();
        RT_SB = 1000.*(sec - t);
        break;
        
    elseif keyCode(escKey)
        ShowCursor;
        RT_SB = 0;
        Screen('CloseAll');
        return;
    end
end

end

Screen('TextSize',p.window,40);    
DrawFormattedText(p.window,textLine,'center',p.yCenter - 250,p.white);



% Static line - bottom
Screen('DrawLine', p.window, p.white, startLine , buttomLine, p.xCenter + 500, buttomLine, lineWidth);
Screen('DrawLine', p.window, p.white, startLine, buttomLine - 10, startLine, buttomLine + 10, lineWidth);
Screen('DrawLine', p.window, p.white, endLine, buttomLine - 10, endLine, buttomLine + 10, lineWidth);
Screen('DrawLine', p.window, p.white, p.xCenter, buttomLine - 10, p.xCenter, buttomLine + 10, lineWidth);


Screen('TextSize',p.window,30);
% Text - bottom
DrawFormattedText(p.window,'0% correct',p.xCenter - 560,buttomLine + 60,p.white);
% DrawFormattedText(p.window,'50% con','center',buttomLine + 60,p.white);
DrawFormattedText(p.window,'100% correct',p.xCenter + 470,buttomLine + 60,p.white);

Screen('DrawDots', p.window, [dotX buttomLine], 20, p.green, [], 2);

Screen(p.window,'Flip');


end






