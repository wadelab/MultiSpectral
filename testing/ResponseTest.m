stimulusOne = [1 2];
stimulusTwo = 2;
trial = 1;
score = 0;

for trial = 1:10
    stimulusOne = Shuffle(stimulusOne);
    disp(stimulusOne(1))    %Stimulus one = 1 or 2 stimulus two always 2
    pause(1)
    disp(stimulusTwo)
    pause(1)
    disp('respond now')     %Were stimulus the same or different? Left arrow = same right = different
    
    response=0;
    
    refTime=GetSecs;
    timeoutTime=5;
    
    while response == 0 && GetSecs-refTime<timeoutTime
        [z,b,c]=KbCheck;
        if find(c)==114 & stimulusOne(1)==stimulusTwo    %Participant has chosen same and they were the same
            response=1;
            disp('correct')
            score=score+1;
        elseif find(c)==114 & stimulusOne(1)~=stimulusTwo    %Participant has chosen different and they were the same
            response=1;
            disp('incorrect')
        elseif find(c)==115 & stimulusOne(1)~=stimulusTwo   %Participant has chosen different and they were different
            response=2;
            disp('correct')
            score=score+1;
        elseif find(c)==115 & stimulusOne(1)==stimulusTwo   %Participant has chosen same and they were different
            response=2;
            disp('incorrect')
        elseif GetSecs-refTime>=timeoutTime     %No response in time
            disp('timeout')
        end
        
    end
   
end

disp(['score = ',num2str(score)])   %Score