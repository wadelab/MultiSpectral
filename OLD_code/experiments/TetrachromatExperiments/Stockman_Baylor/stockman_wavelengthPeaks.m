% Outputs the cone peaks used in the stockmanData file
%
% written by LW on 230713


stock=load('stockmanData.mat');
A=stock.stockmanData;


%Plot the Data
wavelengths=400:2:700;
figure(11)
plot(wavelengths(:),A)


%find the location of the max value, i.e. the peak, for each cone provided
%in the data file
location_column=zeros(3,1);
for f=1:size(A(:,2));
[val,location]=max(A(f,:));
location_column(f,:)=location;
end


% Output the actual peak wavelength, rather than just the column number
idx=sub2ind(size(wavelengths),location_column);
StockmanConePeaks=wavelengths(idx)

