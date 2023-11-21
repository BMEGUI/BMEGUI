function [s]=skewness(Z);% skewness                  - experimental skewness coefficient (Jan 1,2001)%% Compute the experimental skewness coefficients for% a set of variables. The skewness coefficient is a% measure of the asymmetry of a distribution (mean and% standard deviation are obtained from the mean.m and% std.m functions, respectively). The theoretical skewness% coefficient is defined in a way that it is equal to zero% for symmetric distributions, lower than zero for lower% tailed distributions and greater than zero for upper% tailed distributions.%% SYNTAX :%% [s]=skewness(Z);%% INPUT :%% Z    n by nv    matrix of values for the different variables, where%                 each column corresponds to the values of one variable.%% OUTPUT :%% s    1 by nv    vector of estimated skewness coefficients.[m,n]=size(Z);u1=mean(Z);u2=(std(Z).^2);dev=(Z-kron(ones(m,1),u1));u3=sum(dev.^3)/(m-1);s=u3./(u2.^(3/2));