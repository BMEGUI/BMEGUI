function [z]=other2gauss(y,yfile,cdfyfile,method);% other2gauss               - transform from an arbitrary pdf to a Gaussian pdf (Jan 1,2001)%% Do the monotonic transformation from arbitrary distributed% values toward values which are zero mean unit variance Gaussian% distributed. The transformation is based on the relation% P[Z<=inv(Fz(Fy(y))], where y and z are the raw and Gaussian% transformed values, respectively, and Fy,Fz are the corresponding% cumulative distribution functions. The cumulative distribution% function of the raw values can be estimated using, e.g., the% kerneldensity.m function. %% SYNTAX :%% [z]=other2gauss(y,yfile,cdfyfile,method);%% INPUT :%% y          n by 1   vector of raw values to be transformed toward%                     Gaussian distributed values.% yfile      k by 1   vector of values used to define the cumulative%                     distribution function for the y values.% cdfyfile   k by 1   vector of the cumulative distribution function%                     values at the yfile values.% method     string   which is optional and specifies the interpolation%                     method to be used. See interp1.m for available%                     methods. Default value is 'linear'. %% OUTPUT :%% z          n by 1   vector of transformed zero mean unit variance%                     Gaussian distributed values associated with the%                     y values.%% NOTE :%% 1- For y values that are outside the definition of the cumulative% distribution given by (yfile, cdfyfile), the corresponding output% z values are coded as NaN's. The minimum and maximum possible values% for z are determined by the gaussinv.m function.%% 2- It is also possible to process several variables at the same time% (multivariate case). It is then needed to specify additional tags% for the y values. These tags are provided as a vector of values that% refer to the variable, the values ranging from 1 to nv, where nv is% the number of variables. E.g., if there are 3 variables, an indexy% column vector must be defined, having same number of elements than y% (the function will also accepts a single integer value if all the% values belong to the same variable). The y and indexy vectors are% grouped using the MATLAB cell array notation, so that y={y,indexy}% is now the correct input variable. The yfile and cdfyfile vectors are% now cell arrays too, where each cell corresponds to the appropriate% vector of values for the corresponding variable.if nargin<4,  method='linear';end;if ~iscell(y),  cdfyinterp=interp1(yfile,cdfyfile,y,method);  z=gaussinv(cdfyinterp,[0 1]);else  index=y{2};  if length(index)==1,    cdfyinterp=interp1(yfile{index},cdfyfile{index},y{1},method);    z=gaussinv(cdfyinterp,[0 1]);  else    n=length(y{1});    z=zeros(n,1)*NaN;    nv=max(index);    for i=1:nv,      indexi=find(index==i);      cdfyinterp=interp1(yfile{i},cdfyfile{i},y{1}(indexi),method);      z(indexi)=gaussinv(cdfyinterp,[0 1]);    end;  end;end;