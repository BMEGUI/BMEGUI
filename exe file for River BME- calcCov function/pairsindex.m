function [idxpairs]=pairsindex(c1,c2,rLag,rLagTol,dist,method)

% pairsindex                 - finds pairs of points separated by a given distance interval
%
% finds pairs of points separated by a given distance interval
%
% SYNTAX :
%
% [idxpairs]=pairsindex(c1,c2,rLag,rLagTol,dist,method)
%
% INPUT : 
%
% c1        n1 by 2   matrix of coordinates for the locations in the first
%                     set. Each line in c1 corresponds to the vector of
%                     coordinates at a location, so the number of columns is
%                     equal to two. The circles symbols plotted at the extremity
%                     of the line segments refer to coordinates in the c1 matrix.
% c2        n2 by 2   matrix of coordinates for the locations in the second set,
%                     using the same conventions as for c1. The star symbols
%                     plotted at the extremity of the line segments refer to
%                     coordinates in the c2 matrix.
% rLag      nr by 1   vector with the r lags
% rLagTol   nr by 1   vector with the tolerance for the r lags
%                       giving the limits of the distance classes that are
%                       used for estimating the covariance.
%                       The distance classes are closed on the left and closed on
%                       the right.
% dist      cell      optional parameter giving the function to calculate distances.
%                     dist{1} is the name of the distance function, such that the
%                     distances between the points c1 and c2 is calculated using 
%                     [d]=eval([dist{1},'(c1,c2)']), where c1 and c2 are n1 by 2 and 
%                     n2 by 2 matrices, respectively, and d is a n1 by n2 matrix of 
%                     distances between c1 and c2.
%                     dist{2} is an optional parameter. Hence when length(dist)>1, then the
%                     distance matrix is calculated using [d]=eval([dist{1},'(c1,c2,dist{2})'])
%                     Note: The default is dist={'coord2dist'}
% method    string    that contains the name of the method used for computing
%                     the distances between pairs of locations. method='kron'
%                     uses a Kronecker product, whereas method='kronloop' uses loop
%                     for one end point of the pairs and kronecker products for the
%                     other endpoint, and finally method='superblock' uses superblocks,
%                     and kronecker products for each pairs of superblock.  
%                     Using 'kron' is faster for a small number of
%                     locations but may suffer from memory size limitation.
%                     depending on the memory available, as it requires the storage 
%                     of a distance matrix. Use the 'kron' use most memory, 'kronloop'
%                     uses less memory, and 'superblock' might use the least, but it
%                     does not work with all the options.
%                     All  methods yield exactly the same estimates.
%                     The default is 'kron'       if n1*n2<500*500
%                                    'kronloop'   if 500*500<=n1*n2
%
% OUTPUT :
%
% idxpairs  nc by 1   cell array, each cell is a matrix of index values for the coordinates 
%                     in c1 and c2 that satisfy the distances requirements of class [rcl(i) rcl(i+1)]. 
%                     Each line of index refers to a couple of indexes for the coordinates in c1 and c2. 
%                     The first and second column of index refer to coordinates belonging to c1 and c2,
%                     respectively, so the number of columns is equal to two.

n1=size(c1,1);
n2=size(c2,1);
nr=length(rLag);

if nargin<5
  dist{1}='coord2dist';
else
  if ~iscell(dist)
    error('dist must be a cell array');
  end
end
if nargin<6, 
  if n1*n2<500*500, method='kron'; 
  else,             method='kronloop';
  end
end

if (n1<2 | n2<2) & strcmp(method,'superblock')
  disp('warning: changing method to kron because c1 or c2 has only one point');
  method='kron';
end
  
switch method
case 'kron'
  switch dist{1}
    case 'coord2dist'
      D=eval([dist{1},'(c1,c2)']);
    case 'coord2distRiver'
      D=eval([dist{1},'(c1,c2,dist{2})']);
  end;
  for ir=1:nr
    [i j]=find( rLag(ir)-rLagTol(ir)<=D  & D<=rLag(ir)+rLagTol(ir) );
    idxpairs{ir}=[i j];
  end
case 'kronloop'
  for ir=1:nr
    idxpairs{ir}=[];
  end
  for i=1:n1,
    switch dist{1}
      case 'coord2dist'
        d=eval([dist{1},'(c1(i,:),c2)']);
      case 'coord2distRiver'
        d=eval([dist{1},'(c1(i,:),c2,dist{2})']);
    end;
    for ir=1:nr
      j=find( rLag(ir)-rLagTol(ir)<=d  & d<=rLag(ir)+rLagTol(ir) );
      idxpairs{ir}=[idxpairs{ir};[i*ones(size(j(:))) j(:)]];
    end
  end
case 'superblock'
  n=10;                   % the domain is divided in n by n superblocks
  x1min=min(c1(:,1));     % Find the limits of the superblocks for c1
  y1min=min(c1(:,2));
  x1max=max(c1(:,1));
  y1max=max(c1(:,2));
  dx1=(x1max-x1min)/n;
  dy1=(y1max-y1min)/n;
  x2min=min(c2(:,1));     % Find the limits of the superblocks for c2
  y2min=min(c2(:,2));
  x2max=max(c2(:,1));
  y2max=max(c2(:,2));
  dx2=(x2max-x2min)/n;
  dy2=(y2max-y2min)/n;
  id1=(1:n1)';
  id2=(1:n2)';
  %                                                 Process the c1 points
  c1sb=1+floor([(c1(:,1)-x1min)/dx1 (c1(:,2)-y1min)/dy1]);
  c1sb(c1sb==n+1)=n+0*c1sb(c1sb==n+1);
  c1sb=c1sb(:,1)+n*(c1sb(:,2)-1);          % index for each point of which superblock it belongs to   
  sb_idx1=unique(sort(c1sb));               % index of non empty superblocks
  i=mod(sb_idx1,n);
  i(i==0)=n+i(i==0);
  j=(sb_idx1-i)/n+1;
  sb_c1=[x1min+(i-0.5)*dx1 y1min+(j-0.5)*dy1];  % coordinates of the non empty superblocks
  for i=1:length(sb_idx1)                   % find which points are in each  non empty superblock
    sb_set1{i}=id1(c1sb==sb_idx1(i));       % set of points in each non-empty superblock
    sb_n1(i)=length(sb_set1{i});            % number of points in each non-empty superblock
  end
  %                                                 Process the c2 points
  c2sb=1+floor([(c2(:,1)-x2min)/dx2 (c2(:,2)-y2min)/dy2]);
  c2sb(c2sb==n+1)=n+0*c2sb(c2sb==n+1);
  c2sb=c2sb(:,1)+n*(c2sb(:,2)-1);          % index for each point of which superblock it belongs to
  sb_idx2=unique(sort(c2sb));               % index of non-empty superblocks
  i=mod(sb_idx2,n);                         
  i(i==0)=n+i(i==0);                       
  j=(sb_idx2-i)/n+1;                        
  sb_c2=[x2min+(i-0.5)*dx2 y2min+(j-0.5)*dy2]; % coordinates of the non-empty superblocks
  for i=1:length(sb_idx2)                   % find which points are in each non empty superblock
    sb_set2{i}=id2(c2sb==sb_idx2(i));       % set of points in each non-empty superblock            
    sb_n2(i)=length(sb_set2{i});            % number of points in each non-empty superblock                 
  end                                      
  if sum(sb_n1)~=n1 | sum(sb_n2)~=n2         
    error('Something is fishy in here');   
  end;                                     
  %                                        Loop through the distance classes
  dr=sqrt(dx1^2+dy1^2)+sqrt(dx2^2+dy2^2);  
  for ir=1:nr                              
    %                                      Find the super blocks corresponding to the distance classes
    isb=[];                                
    jsb=[];                                
    for i=1:length(sb_idx1)  
      switch dist{1}
        case 'coord2dist'
          d=eval([dist{1},'(sb_c1(i,:),sb_c2)']);
        case 'coord2distRiver'
          d=eval([dist{1},'(sb_c1(i,:),sb_c2,dist{2})']);
      end;
      j=find( rLag(ir)-rLagTol(ir)-dr<=d  & d<=rLag(ir)+rLagTol(ir)+dr ); 
      isb=[isb;i*ones(size(j(:)))];
      jsb=[jsb;j(:)];
    end
    idxpairs{ir}=[];
    for k=1:length(isb)            % For each selected superblock pair find the pairs of points corresponding to distance lag
      switch dist{1}
        case 'coord2dist'
          Dk=eval([dist{1},'( c1(sb_set1{isb(k)},:) , c2(sb_set2{jsb(k)},:) )']);
        case 'coord2distRiver'
          Dk=eval([dist{1},'( c1(sb_set1{isb(k)},:) , c2(sb_set2{jsb(k)},:) , dist{2} )']);
      end;
      [i j]=find( rLag(ir)-rLagTol(ir)<=Dk  & Dk<=rLag(ir)+rLagTol(ir) );
      i=i(:);
      j=j(:);
      idxpairs{ir}=[idxpairs{ir}; [sb_set1{isb(k)}(i) sb_set2{jsb(k)}(j)] ];    
    end
  end
otherwise
  error('method must be equal to kron, kronloop, or superblock');
end

for ir=1:nr
  idxpairs{ir}=sortrows(idxpairs{ir});
end



%%
%%
%%
%%


%%
%%                   Added for BMEGUI: P Jat (May, 2011)
%%
function [rD]=coord2distRiver(c1,c2,riverTopology);

% coord2distRiver                 - computes the distance between two points along a river network.  
%
%SYNTAX:
%
%[rD]=coord2distRiver(c1,riverTopology);
%
%
%INPUT:
%
%c1         n1 x 5      First set of coordinates along the river network.  First column is a unique reach ID
%                       the Second column is the longitudinal distance along that reach starting from 
%                       downstream.
%                       column 1: X position (in original units, i.e. lat/long)
%                       column 2: Y position
%                       column 3: Reach ID
%                       column 4: Distance to DS End
%                       column 5: Time (only if using space/time)
%
%c2         n1 x 5      Second set of coordinates along the river network.  First column is a unique reach ID
%                       the Second column is the longitudinal distance along that reach starting from 
%                       downstream.
%                       column 1: X position (in original units, i.e. lat/long)
%                       column 2: Y position
%                       column 3: Reach ID
%                       column 4: Distance to DS End
%                       column 5: Time (only if using space/time)
%
%
%riverTopology     nr x 4      nr = # of reaches.  Matrix where each line identifies a reach.
%                              First Column     = Unique Reach ID
%                              Second Column    = Order of Reach
%                              Third Column     = Downstream Reach ID
%                              Fourth Column    = Longitudinal Length of Reach
%
%
%OUTPUT:
%
%rD          n1 x n1     Matrix of Distances whose dimensions equal the total # of reaches ID in n1,n2
%
%
%


%Check for errors in c1,c2 and riverTopology
sizec1=size(c1);
sizec2=size(c2);
sizerp=size(riverTopology);
clear i j;
if sizec1(2)<4
    error('c1 must be of size n1 x 4 (space) or n1 x 5 (space/time)');
end;

if sizec2(2)<4
    error('c2 must be of size n1 x 4 (space) or n1 x 5 (space/time)');
end;

if sizerp(2)~=4
    error('riverTopology must be of size nr x 4');
end;

%for i=1:length(c1(:,3))
 %   if c1(i,4) > riverTopology(c1(i,3),4)
  %      error(sprintf('error in row %d of c1, Total Reach Length must be greater than distance in c1',i));
   %   end;
    %end;

%for i=1:length(c2(:,3))
 %   if c2(i,4) > riverTopology(c2(i,3),4)
  %      error(sprintf('error in row %d of c1, Total Reach Length must be greater than distance in c2',i));
   % end;
%end;


clear i j;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate the distance matrix

for i=1:size(c1,1)
  for j=1:size(c2,1)
    clear d;
    k=1;
    firstreachOrder=riverTopology(c1(i,3),2);
    secondreachOrder=riverTopology(c2(j,3),2);
    if c1(i,3) == c2(j,3)
      d(1)=abs(c1(i,4)-c2(j,4));%Check if points are on the same reach
    else
      if firstreachOrder>secondreachOrder %Determine if one point is directly downstream of another
        reachDS=riverTopology(c1(i,3),3);
        secondreach=c2(j,3);
      else
        reachDS=riverTopology(c2(j,3),3);
        secondreach=c1(i,3);
      end;
      ID=1;
      reachIDs=[];
      idx=[];
      while reachDS ~= 0 %find the DS reaches to determine if the points are DS of each other
        reachIDs(ID)=reachDS;
        reachDS=riverTopology(reachDS,3);
        ID=ID+1;
      end;
      idx=find(secondreach==reachIDs);
      if isempty(idx) %If not directly downstream, then calculate distance the following way
        firstreachDS=riverTopology(c1(i,3),3);
        secondreachDS=riverTopology(c2(j,3),3);
        d(1)=c1(i,4)+c2(j,4);
        while firstreachOrder ~= secondreachOrder
          if firstreachOrder > secondreachOrder
            d(k+1)=riverTopology(firstreachDS,4);
            firstreachOrder=riverTopology(firstreachDS,2);
            firstreachDS=riverTopology(firstreachDS,3);
            k=k+1;
          else
            d(k+1)=riverTopology(secondreachDS,4);
            secondreachOrder=riverTopology(secondreachDS,2);
            secondreachDS=riverTopology(secondreachDS,3);
            k=k+1;
          end;
        end;
        while firstreachDS ~= secondreachDS
          d(k+1)=riverTopology(firstreachDS,4) + riverTopology(secondreachDS,4);
          firstreachDS=riverTopology(firstreachDS,3);
          secondreachDS=riverTopology(secondreachDS,3);
          k=k+1;
        end;        
      else  %If points are directly downstream, calculate distance this way
        if c1(i,3) > c2(j,3)
          d(1)=c1(i,4); 
          reachDS=riverTopology(c1(i,3),3);
          while reachDS ~= c2(j,3)
            d(k+1)=riverTopology(reachDS,4);
            k=k+1;
            reachDS=riverTopology(reachDS,3);
          end;
          d(k+1)=riverTopology(c2(j,3),4)-c2(j,4);          
        elseif c1(i,3) < c2(j,3)
          reachDS=riverTopology(c2(j,3),3);
          d(1)=c2(j,4); 
          while reachDS ~= c1(i,3) 
            d(k+1)=riverTopology(reachDS,4);
            reachDS=riverTopology(reachDS,3);
            k=k+1;
          end;
          d(k+1)=riverTopology(c1(i,3),4)-c1(i,4);             
        else
          clear d;
          d(1)=abs(c1(i,4)-c2(j,4));
        end; 
      end;
    end;
      rD(i,j)=sum(d); %The final distance matrix
  end;
end;
      

        
    