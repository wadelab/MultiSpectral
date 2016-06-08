function [ConeExcitation, ShiftedConeExcitation, data] = plotConeExcitations_ForShiftedCones
% [ConeExcitation, ShiftedConeExcitation, data] = plotConeExcitations_ForShiftedCones
%
% Calculates and plots the cone excitation values for a given condition.
%
% Uses the modulation produced for the condition and the background LED
% level. Calculates the difference in cone excitation from background alone 
% vs. background+modulation.
%
% Prompts for the data file that contains the relevant LED and cone spectra,
% as well as the amp values for the modulation in that particular condition
% N.B The data file is outputed by the cone isolation experiment - all 
% necessary info in within the dpy structure.
%
% Cone excitation values are transformed to cone contrasts based on the
% known cone contrast level set for the condition, and the cone excitation
% value for the isolated cone: all cone excitation levels are divided by 
% the max cone excitation (the isolated cone), then multiplying by the cone 
% contrast.
%
% The process above is repeated to calculate how the cone excitations
% differ when the cone spectra of the 'observer' is shift relative to the
% spectra used to calculate the stimuli.  These are then plotted as the
% difference between the values for the cone spectra used in the stimulus
% and the shifted spectra.
%
% Outputs the calculated values for the original cone spectra in:
%   ConeExcitation  
%
% Outputs the calculated values for the shifted cone spectra in:
%   ShiftedConeExcitation
%
% Outputs the data file that was originally imported in:
%   data
%
% Make sure the relevant directory containing the data files is in the
% path.
%
% written by LEW 060616


%Prompts to select a data file to load e.g.
%Sub001_ExptL_Fre2_Rep1_20160601T102056.mat
theData=uigetfile(pwd,'Select a file containing a single data condition');
data=importdata((theData));

%store the LED spectra
LEDspec=data.dpy.LEDspectra;

%store the LED amps (given in vals +/- above or below half output of
%leds)
LEDamps=data.dpy.targetLEDoutput(1,:)'; %just the first contrast condition (row)

%store the cone spectra that was used to generate the amps
coneSpectra=data.dpy.coneSpectra;

%save condition parameters
contrastPercentLevel=data.dpy.contrastLevelTested(1,1)*100; %for first condition, x100 for %
condition=data.dpy.ExptID; %expt ID
WLs=data.dpy.WLrange; %wavelange range used

% use some predefined spectra numbers to identify which cone is in use,
% this is used to modelled what happens when a cone is shifted (see below).
% Be careful here though, in case anything changes in terms of cone spec
% ordering, etc. - this isn't really future proof.
if data.dpy.NumSpec==4
    conePos=[1,2,3,4];
    coneLabels={'L','LP','M','S'};
    coneColours=[0.7,0,0;1,0.4,0;0,0.7,0;0,0,0.8];
    %coneIndx=strcmp(coneLabels,condition);
elseif data.dpy.NumSpec==3
    conePos=[1,2,3];
    coneLabels={'L','M','S'};
    coneColours=[0.7,0,0;0,0.7,0;0,0,0.8];
    %coneIndx=strcmp(coneLabels,condition);
end

%calculate the background LED levels - half max (N.B. that these values are
%normalised across all LEDs (so relative intensity is still intact), with 
%the max value of all LEDs set at 1.
BackgroundLEDs=LEDspec*0.5; %half value.
BackgroundMod=sum(BackgroundLEDs,2); %sum across LED spectra for background modulation

%get modulation used in this condition by multiplying LED spec by the amps
PosMod=LEDspec*LEDamps; %the (positive) modulation

%Adjust the modulation to the same scale as the Background by dividing by
%2048 - this is half max output val (bit depth) for the LEDs (i.e. the LEDs 
%above are at half their max)
PosModAdjust=PosMod/2048;

%calculate the background plus stimulus modulation
BackgroundPlusStim=BackgroundMod+PosModAdjust;

% Calculate the cone excitations for the background modulation on it's own,
% and for the background plus the stimulus modulation.

% For each cone
for thisCone=1:size(coneSpectra,2)
    curCone=coneSpectra(:,thisCone)'; %store current spectra (cone to be calculated)
    % cone excitation is the sum of Mod*coneSpectra.
    % calculate for the background modulation
    ConeExcitation.Background.AcrossLEDs(1,thisCone)=sum(BackgroundMod.*curCone'); 
    % then calculate for the background+Stim modulation
    ConeExcitation.BackPlusStim.AcrossLEDs(1,thisCone)=sum(BackgroundPlusStim.*curCone');
end %next cone

%Get the difference in cone excitations between the background and the
%background+stimulus.  Round for convenience.
ConeExcitation.OverallConeExcitation=round((ConeExcitation.BackPlusStim.AcrossLEDs-ConeExcitation.Background.AcrossLEDs),5);

% to transform the excitation values into cone contrast, get the max cone
% excitation level
maxConeEx=max(abs(ConeExcitation.OverallConeExcitation));
%divide each by the max, then multiply by the known contrast level for the
%condition
ConeExcitation.ConeContrast=(ConeExcitation.OverallConeExcitation/maxConeEx)*contrastPercentLevel;



%% Now we can see whether adjusting the cone spectra peaks affects the cone excitations
% this is useful for modelling how much the 'silenced' cones are actived
% if the observers actual cone fundamentals are slightly different to those
% used to create the stimulus
% N.B. that this is specifically testing the effect of the shift for the
% given condition, re-run the script selecting different data files to save
% out plots/data for different conditions

% first we need to specify what level of shift to test
maxShift=2;%Shift to test either side in nm 
%calculate the step size of the wavelengths used
stepSize=WLs(2)-WLs(1); %look at difference between two wavelength values

%calculate how many steps are needed to cover the full range 
NumberOfSteps=(maxShift*2)/stepSize;
%convert so equal number of steps either side of 0 (inc. 0, which is no shift)
rangeVals=(-(NumberOfSteps/2):1:NumberOfSteps/2)'; 
%store the actual shifts in wavelengths for plotting
WLshiftVals=-maxShift:stepSize:maxShift;
ShiftedConeExcitation.WLshiftVals=WLshiftVals; %store the wavelength shift values

%calculate the shifted cone spectras for each of the shifts - this is a
%pretty basic method, literally adds/removes rows from start/end of column
%to physically adjust the spectra relative to the wavelengths.  Adds zeros
%to the relevant end depending on whether spectra is shifted to shorter or
%longer wavelengths.  I've done this rather than creating them with e.g. a
%Baylor nomogram function, because this way they most closely match the
%stockman sharpe fundamentals that were actually used to create the
%stimulus.
theFig=figure(); %for plotting the change in cone contrast vs shift
set(theFig,'Color','w','Position',[1793 245 450 550])

%loop through each cone
for thisCone=1:size(coneSpectra,2)
    isolatedCone=coneSpectra(:,thisCone);
    curConeLabel=coneLabels{thisCone}; %get the label for the current cone
    
    %for each shift level
    for thisShift=1:length(rangeVals)
        theShift=rangeVals(thisShift); %what shift is required, use thisShift as indx
        %create a name for the shift for saving out values
        if theShift<0
            polarity='Neg';
        elseif theShift>0
            polarity='Pos';
        else
            polarity='None';
        end
        wlShift=sprintf('%.1f',abs(theShift*stepSize)); %save the shift in terms of actual wl shift (nm)
        splitVal=strsplit(wlShift,'.'); %string split so can save name without full stops
        shiftName=sprintf('Shift%s%s_%snm',polarity,splitVal{1},splitVal{2}); %create name
        
        %save the spectra with new name to avoid overriding it with each
        %loop
        ShiftedCone=isolatedCone;
        if theShift<0 %if shifting to shorter wavelengths, cut rows from start, add zeros to end
            %resave the spectra without the first n rows, depending on size of
            %shift.  Note need to +1 so the first row that is kept is the one
            %after the number of rows that need to be removed.
            ShiftedCone=ShiftedCone(abs(theShift)+1:end);
            %add zeros to the end of the column (same number of rows that were
            %removed), this ensures number of rows always match the right
            %number of wavelength values.
            ShiftedCone(end+1:end+abs(theShift))=0;
        elseif theShift>0 %if shifting to longer wavelengths, add zeros to start, cut rows from end
            %remove the necessary number of rows from end of the column
            ShiftedCone(end-abs(theShift):end)=[];
            %create some zeros - same number as the number of rows removed
            theZeros=zeros(theShift+1,1);
            %concatenate to start of column
            ShiftedCone=cat(1,theZeros,ShiftedCone);
        end
        
        %now, for this shifted cone spectra we will do the same steps for
        %getting the cone excitations as we did above
        
        % Calculate the cone excitations for the background modulation
        ShiftedConeExcitation.(curConeLabel).(shiftName).Background.AcrossLEDs(1,thisCone)=sum(BackgroundMod.*ShiftedCone);
        % Calculate cone excitation to the BackgroundPlusStim
        ShiftedConeExcitation.(curConeLabel).(shiftName).BackPlusStim.AcrossLEDs(1,thisCone)=sum(BackgroundPlusStim.*ShiftedCone);

        %Get the difference in cone excitations between the background and
        %background+stimulus.  Round for convenience.  
        ShiftedConeExcitation.(curConeLabel).(shiftName).ConeExcitation(1,thisCone)=...
            round((ShiftedConeExcitation.(curConeLabel).(shiftName).BackPlusStim.AcrossLEDs(1,thisCone)-...
            ShiftedConeExcitation.(curConeLabel).(shiftName).Background.AcrossLEDs(1,thisCone)),5);
        %store the shift value
        ShiftedConeExcitation.AllShifts.shiftRows(thisShift,1)=theShift;
        %store the cone excitations for all shifts in one matrix, for
        %plotting more easily
        ShiftedConeExcitation.AllShifts.ConeExcitation(thisShift,thisCone)=...
            ShiftedConeExcitation.(curConeLabel).(shiftName).ConeExcitation(1,thisCone);
        %calculate difference between original (0 shift) and shifted cone
        %excitations
        ShiftedConeExcitation.ShiftFromOriginal(thisShift,thisCone)=...
            abs(ConeExcitation.OverallConeExcitation(1,thisCone)-...
            ShiftedConeExcitation.AllShifts.ConeExcitation(thisShift,thisCone));
    
        %calculate the estimated cone contrasts using the max values from
        %before
        ShiftedConeExcitation.ConeContrast(thisShift,thisCone)=(ShiftedConeExcitation.AllShifts.ConeExcitation(thisShift,thisCone)...
            /maxConeEx)*contrastPercentLevel;
        
        %calculate the change in cone contrast between original and shifted
        %cone spectra
        ShiftedConeExcitation.ConeContrastChange(thisShift,thisCone)=...
            abs(ShiftedConeExcitation.ConeContrast(thisShift,thisCone)-...
            ConeExcitation.ConeContrast(1,thisCone));
        
    end %next shift level
    
    %plot the data for this cone
    hold on
    theData=plot(WLshiftVals,ShiftedConeExcitation.ConeContrastChange(:,thisCone));
    set(theData,'LineWidth',4,'MarkerFaceColor',coneColours(thisCone,:),...
        'Color',coneColours(thisCone,:),'MarkerEdgeColor',coneColours(thisCone,:),...
        'Marker','o','MarkerSize',6)
end %next cone

%set properties of the figure to make it look a bit better :-)
%maxLevelToPlot=max(max(ShiftedConeExcitation.ShiftFromOriginal)); %find max level to be plotted for Ylim can be set
maxLevelToPlot=max(max(ShiftedConeExcitation.ConeContrastChange)); %find max level to be plotted for Ylim can be set
%set axis properties
set(gca,'FontName','Arial','FontSize',18,'LineWidth',3,'YLim',[0,round(maxLevelToPlot,1)],...
    'Box','on','XLim',[-(maxShift),(maxShift)],'Position',...
    [0.18 0.11 0.7541 0.8150],'XTick',-maxShift:1:maxShift)
%set X and Y labels and legend
theXlabel=xlabel('Shift in Peak Wavelength (nm)');
theYlabel=ylabel('Change in Cone Contrast (%)');
theLeg=legend(coneLabels);
set(theXlabel,'FontName','Arial','FontSize',22)
set(theYlabel,'FontName','Arial','FontSize',22)
posY=get(theYlabel,'Position');
posY(1)=-(maxShift+0.6);
set(theYlabel,'Position',posY)
set(theLeg,'FontName','Arial','FontSize',22,'Box','off','Location','North')

%set details for the title
if strcmp(condition,'LM')
    condition='L-M';
elseif strcmp(condition,'LMS')
    condition='L+M+S';
elseif length(condition)==1
    condition=sprintf('%s cone isolating',condition);
elseif strcmp(condition,'LP')
    condition='L-prime cone isolating';
end
theTitle=title(sprintf('%s',condition));
set(theTitle,'FontName','Arial','FontSize',24)

end