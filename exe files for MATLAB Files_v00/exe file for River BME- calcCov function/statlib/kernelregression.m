function [zk]=kernelregression(ck,c,z,v,order,options);% kernelregression          - prediction using a Gaussian kernel regression method (Jan 1,2001)%% Implementation of the regression.m function in a moving% neighbourhood context. Regression is conducted locally% at a set of coordinates using a least squares estimation% procedure for a linear regression model, where the% deterministic part of the linear model is a polynomial of% arbitrary order. Instead of using ordinary least squares,% the function uses a diagonal covariance matrix, where the% variances are inversely proportional to the weights provided% by a Gaussian kernel, so that weights are monotonically % decreasing with the distance from the estimation location. %% SYNTAX :%% [zk]=kernelregression(ck,c,z,v,order,options); %% INPUT :%% ck        nk by d   matrix of coordinates for the estimation locations.%                     A line corresponds to the vector of coordinates at%                     an estimation location, so the number of columns%                     corresponds to the dimension of the space. There is%                     no restriction on the dimension of the space.% c         n by d    matrix of coordinates for the locations of the values,%                     with the same conventions as for ck.% z         n by 1    vector of values at the c coordinates.% v         scalar    variance of the Gaussian kernel along the spatial axes.% order     scalar    order of the polynomial mean along the spatial axes%                     specified in c, where order>=0.% options   scalar    optional parameter that can be used if default value%                     is not satisfactory (otherwise this parameter can simply%                     be omitted from the input list of variables). options is%                     equal to 1 or 0, depending if the user wants or does not%                     want to display the order number of the location which is%                     currently processed by the function (default value is 0).%% OUTPUT :%% zk        nk by 1   vector of estimated mean values at the estimation locations.%                     A value coded as NaN means that no estimation has been%                     performed at that location due to the lack of available data.%% NOTE :%% 1- It is worth noting that when order=0, the kernelregression.m% function is doing a simple moving average estimation where the% weights are proportionally inverse to the values of the Gaussian kernel.%% 2- To the opposite of the regression.m function, it is only possible to% process a single variable using this function, but space/time data are% allowed. In that case, the convention is that the last column of the c% and ck matrices of coordinates corresponds to the time axis. The order% variable is then a 1 by 2 vector, where order(1) is the order of the% spatial polynomial and order(2) is the order of the temporal polynomial.% The v variable is then a 1 by 2 vector, where v(1) and v(2) are the% variances of the Gaussian kernel along the spatial axes and the temporal% axis, respectively.nk=size(ck,1);if nargin<6,  options1=0;else  options1=1;  num2strnk=num2str(nk);end;zk=zeros(nk,1)*NaN;nmax=Inf;isST=(length(v)==2);if isST==1,  dmax(1)=4*sqrt(v(1));  dmax(2)=4*sqrt(v(2));  dmax(3)=1;             % this value is arbitrary as all locations are kept in the neighbourhoodelse  dmax=4*sqrt(v);end;for i=1:nk,  [csub,zsub,dsub,nsub]=neighbours(ck(i,:),c,z,nmax,dmax);  if nsub>0,    csub=csub-ck(i);    if isST==1,      w=gausspdf(dsub(:,1),[0 v(1)]).*gausspdf(dsub(:,2),[0 v(2)]);    else      w=gausspdf(dsub,[0 v]);    end;    w=1./w;    K=diag(w);    [best,Vbest]=regression(csub,zsub,order,K);    zk(i)=best(1);  end;  if options1==1,    disp([num2str(i),'/',num2strnk]);  endend;