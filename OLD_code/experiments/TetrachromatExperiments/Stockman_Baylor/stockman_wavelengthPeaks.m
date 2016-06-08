% Outputs the cone peaks used in the stockman01nmCF.mat file
%
% written by LW on 230713


load('stockman01nmCF.mat');
LMS=[stockman.Lcone';stockman.Mcone';stockman.Scone'];
wavelengths=stockman.wavelength';

%Plot the Data
figure()
plot(wavelengths(:),LMS)


%find the location of the max value, i.e. the peak, for each cone provided
%in the data file
location_column=zeros(3,1);
for f=1:size(LMS(:,2));
[val,location]=max(LMS(f,:));
location_column(f,:)=location;
end


% Output the actual peak wavelength, rather than just the column number
idx=sub2ind(size(wavelengths),location_column);
StockmanConePeaks=wavelengths(idx)

