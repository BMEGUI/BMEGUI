function markerplot(c,z,sizelim,Property,Value,zrange);% markerplot                - plot of values at 2-D coordinates using markers (Jan 1,2001)%% Plot the values of a vector at a set of two dimensional coordinates% using symbols of varying sizes such that the size of the displayed% symbols at these coordinates is a function of the corresponding values. %% SYNTAX :%% markerplot(c,z,sizelim,Property,Value,zrange); %% INPUT :%% c           n by 2 matrix of coordinates for the locations to be displayed.%                    Each line corresponds to the vector of coordinates at a%                    location, so the number of columns is equal to two.% z           n by 1 column vector of values to be coded as markers.% sizelim     1 by 2 vector that contains the minimum and maximum values in pixels%                    for the size of the symbols to be displayed. The minimum and%                    maximum size values are associated with the minimum  and maximum%                    values in z, respectively. The size of the symbols for values in%                    between these minimum and maximum are obtained by linear interpolation.% Property    1 by k cell array where each cell is a string that contains a legal name%                    of a plot object property. This variable is optional, as default%                    values are used if Property is missing from the input list of variables.%                    Execute get(H), where H is a plot handle, to see a list of plot object%                    properties and their current values. Execute set(H) to see a list of%                    plot object properties and legal property values. See also the help%                    for plot.m.% Value       1 by k cell array where each cell is a legal value for the corresponding plot%                    object property as specified in Property.% zrange      1 by 2 optional vector specifying the minimum and maximum value of%                    the range of z values scaled with the symbol sizes.  %                    The default is zrange=[min(z) max(z)]%                    If zrange is empty then the default values are used.%% NOTE :%% For example,%% markerplot(c,z,sizelim,Property,Value);% % where sizelim=[5 20];%       Property={'Marker','MarkerEdgeColor','MarkerFaceColor'};%       Value={'^',[0 0 1],[1 0 0]};%% will plot red triangles with a blue border that have a % MarkerSize value between 5 and 20 pixels. By default, % markerplot(c,z,sizelim) will use disks with the default % properties for plot.m.if nargin>3,  if ~iscell(Property),    Property={Property};    Value={Value};    noptions=1;  else    noptions=length(Property);  end;else  noptions=0;end;if nargin<6 | isempty(zrange)  zrange=[min(z(:)) max(z(:))];end;[n,d]=size(c);if d~=2, error('c must be a n by 2 matrix'); end;if size(z,2)~=1, error('z must be a column vector'); end;if size(z,1)~=n, error('c and z must have the same number of rows'); end;c=c(~isnan(z),:);z=z(~isnan(z),:);if length(z)==0 return; endtest=(ishold==1);minz=zrange(1);maxz=zrange(2);if maxz==minz,  error('At least two values of z must be different');end;n=length(z);for i=1:n,  if z(i)<minz,     s=sizelim(1);  elseif  z(i)>maxz,     s=sizelim(2);  else,       s=interp1([minz maxz],sizelim,z(i));  end  a=plot(c(i,1),c(i,2),'.');  set(a,'MarkerSize',s);  for j=1:noptions,    set(a,Property{j},Value{j});  end;  hold on;end;if test==0,  hold off;end;