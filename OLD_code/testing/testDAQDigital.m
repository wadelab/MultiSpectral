tic

s2 = daq.createSession('ni');

ch2= s2.addAnalogOutputChannel('cDAQ1Mod2', 0, 'Voltage');
data = (sin(linspace(0,2*pi*50,100000)+pi/3)*1.9)'+3; %last number = brightness/amplitude
s2.Rate = 10000;% 10KHz

%data(end,:)=5.5;
figure(2);
plot(data);
s2.queueOutputData(data);


s2.startBackground;


% Now try faking PWM using just the analogue channel
nPulses=100; % Hz of output signal
nSteps=256;
totalFreq=nPulses*nSteps
s2.Rate=totalFreq; % We must run this fast to get the requires update rate and resolution
nStimSecs=0.1;


a=linspace(0,nSteps*nStimSecs*nPulses,totalFreq*nStimSecs);
thisIndex=1;
b=mod(a,nSteps);
c=[];
t=sin(linspace(0,2*pi*50,length(a)))*128+128;
for thisT=1:length(t)


    c(:,thisIndex)=b(:)<t(thisT);
    thisIndex=thisIndex+1;
end

c=c*4.9+0.1;
s2.queueOutputData(c(:));
s2.startForeground;
disp(t);




s2.release();