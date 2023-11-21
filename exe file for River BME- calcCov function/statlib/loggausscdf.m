function [p]=loggausscdf(z,param);% loggausscdf               - log-Gaussian cumulative distribution function (Jan 1,2001)%% Compute the values of the cumulative distribution% function for a log-Gaussian distribution with% specified mean and variance parameters for the% associated Gaussian distribution.%% SYNTAX :%% [p]=loggausscdf(z,param);%% INPUT :%% z        n by k   matrix of values for which the probability%                   distribution function must be computed.% param    1 by 2   parameters of the Gaussian distribution, where :%                   param(1) is the mean of the distribution,%                   param(2) is the variance of the distribution.%% OUTPUT :%% p        n by k   matrix of values for the cumulative probabilities%                   computed at the corresponding z values.m=param(1);v=param(2);if v<0,  error('a variance cannot be negative');end;isnegative=find(z<=0);z(isnegative)=NaN;z=log(z);if v~=0,  z=(z-m)./sqrt(v);  p=((erf(z/sqrt(2))+1)/2);  p(isnegative)=0;else  p=zeros(size(z));  index=find(z>=m);  pdf(index)=1;end;