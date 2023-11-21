function [index]=findpairs(c1,c2);% findpairs                 - identify identical coordinates (Jan 1,2001)%% Find pairs of coordinates that are identical for two diferent% matrices of coordinates.%% SYNTAX :%% [index]=findpairs(c1,c2);%% INPUT :%% c1        n1 by d  matrix of coordinates, where d is the dimension%                    of the space.% c2        n2 by d  matrix of coordinates.%% OUTPUT :%% index     n by 2  vector of indices for identical coordinates%                   in c1 and c2. The first column of index %                   refers to the c1 matrix, whereas the second%                   column of index refers to the c2 matrix.%% NOTE :%% It is possible to specify additional n1 by 1 and n2 by 1 index vectors,% taking integer values from 1 to nv. The values in the index vectors% specify which of the nv variable is known at each one of the corresponding% coordinates. The c1 and c2 matrices of coordinates and the index vectors% are then grouped together using the MATLAB cell array notation, so that% c1={c1,index1} and c2={c2,index2}. Two points are then considered as% identical if both their coordinates and their indexes are identical.% The c1 and c2 matrices cannot contain duplicated coordinates. if iscell(c1),  c1=[c1{1},c1{2}];  c2=[c2{1},c2{2}];end;n1=size(c1,1);n2=size(c2,1);index=zeros(min(n1,n2),2);compt=0;if n1<n2,  for i=1:n1,    distance=coord2dist(c2,c1(i,:));    isnulldist=find(distance==0);    if ~isempty(isnulldist),      compt=compt+1;      npairs=length(isnulldist);      index(compt,:)=[i,isnulldist];    end;  end;else  for i=1:n2,    distance=coord2dist(c1,c2(i,:));    isnulldist=find(distance==0);    if ~isempty(isnulldist),      compt=compt+1;      npairs=length(isnulldist);      index(compt,:)=[isnulldist,i];    end;  end;end;index=index(1:compt,:);