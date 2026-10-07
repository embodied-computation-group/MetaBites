
function exitNow = MetaBites_instructions(window, text)


%% setup

sx=120;
sy='center';
wrapat=60;
pg = text;
Screen('TextSize', window,40);

j=1;
while j <= length(text)
    DrawFormattedText(window,[pg{j}], 'center', 'center');
    Screen('Flip',window);
    WaitSecs(.5);
    KbWait();
   
    
    [k s key] = KbCheck();
    switch KbName(key)
        case 'ESCAPE', exitNow = 1; break;
        
        case 'LeftArrow'
            if j > 1, j=j-1; end
            
        case 'space'
            % increment page counter
            j=j+1;
    end
end



end