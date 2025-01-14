function bmeEst(dataFile,paramFile,smeanFile,tmeanFile,outFile1,outFile2,outFile3);
% bmeEst.exe (Ver. 0.1)
%
% Calculate BME estimation
%
% Input: Data file
%        Parameter file
%        Spatial mean trend file
%        Temporal mean trend file
%        Output file1
%        Output file2
% Output: Outputfile

try
    % Get data points and values
    rawdata = dlmread(dataFile);
    rawX = rawdata(:,1);
    rawY = rawdata(:,2);
    rawT = rawdata(:,3);
    rawId = rawdata(:,4);
    rawType = rawdata(:,5);
    rawVal1 = rawdata(:,6);
    rawVal2 = rawdata(:,7);
   % rawVal3 = rawdata(:,8);   % P Jat : for Data type ==3
   % rawVal4 = rawdata(:,9);   % P Jat : for Data type ==4
    
    % Get spatial mean trend
    smeandata = dlmread(smeanFile);
    sptlX = smeandata(:,1);
    sptlY = smeandata(:,2);
    sptlM = smeandata(:,3);

    % Get temporal mean trend
    tmeandata = dlmread(tmeanFile);
    tempG = tmeandata(:,1);
    tempM = tmeandata(:,2);

    % Read parameter file
    [estTime,sptl,temp,metr,nhmax,nsmax,numEstX,numEstY,...
     estLimE,estLimW,estLimN,estLimS,inclDataPts,inclVoronoi,...
     numDispX,numDispY,covm1,covp11,covp12,covp13,...
     covm2,covp21,covp22,covp23,covm3,covp31,covp32,covp33,...
     covm4,covp41,covp42,covp43,minVal,flgLog,flgRemvMean,...
     op1,op3,op4,op8,orderVal] = ...
                textread(paramFile,...
    '%f %f %f %f %d %d %d %d %f %f %f %f %d %d %d %d %s %f %f %f %s %f %f %f %s %f %f %f %s %f %f %f %n %d %d %n %n %n %n %n');

	% Set BME estimation parameters
    dmax = [sptl temp metr];
	if covm2{1} == '0'
	    covmodel = covm1{1};
	    covparam = [covp11 covp12 covp13];
        sill = covp11;
	elseif covm3{1} == '0'
	    covmodel = {covm1{1},covm2{1}};
	    covparam = {[covp11 covp12 covp13],[covp21 covp22 covp23]};
        sill = covp11 + covp21;
	elseif covm4{1} == '0'
	    covmodel = {covm1{1},covm2{1},covm3{1}};
	    covparam = {[covp11 covp12 covp13],[covp21 covp22 covp23],[covp31 covp32 covp33]};
        sill = covp11 + covp21 + covp31;
	else
	    covmodel = {covm1{1},covm2{1},covm3{1},covm4{1}};
	    covparam = {[covp11 covp12 covp13],[covp21 covp22 covp23],[covp31 covp32 covp33],[covp41 covp42 covp43]};
        sill = covp11 + covp21 + covp31 + covp41;
	end
    options=BMEoptions;
    if op1 ~= -1
        options(1) = op1;
    end
    if op3 ~= -1
        options(3) = op3;
    end
    if op4 ~= -1
        options(4) = op4;
    end
    if op8 ~= -1
        options(8) = op8;
    end
    if orderVal == 99
	    order = NaN;
    else
        order = orderVal;
    end
    
  
    % % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %--------------------- River Metric Code: P Jat------------------------
    %Use River Topology if River Dist has to be analyzed (P Jat May,2011)
    existID = exist('stdPathRT.txt', 'file');
    if (existID==2)        
        load riverReaches;
        sk = discretizeRiverNetwork(riverReaches,0.05) ;       
        sdata = unique([rawX,rawY],'rows');        
         if inclDataPts
             idx = (estLimW<=sdata(:,1)) & (sdata(:,1)<=estLimE) & (estLimS<=sdata(:,2)) & (sdata(:,2)<=estLimN) ;
             sdata = sdata(idx,:);
             sk = unique([sk;sdata],'rows');
         end
         sk = [sk,ones(size(sk,1),1)*estTime];
         %convert estimation grid to river points 
         load riverReaches  % saved by 'calcCov(): Line 71
         [skR]=cartesian2riverProj(riverReaches,sk,0.01);
         sk = skR;         
    else    
    %--------------Copied from Original codes------------------------------
        % Create estimation points
        [xg yg] = meshgrid(estLimW:(estLimE-estLimW)/(numEstX-1):estLimE,...
                           estLimS:(estLimN-estLimS)/(numEstY-1):estLimN);
        sk=[xg(:) yg(:)];
        sdata = unique([rawX,rawY],'rows');        
        if inclDataPts
            idx = (estLimW<=sdata(:,1)) & (sdata(:,1)<=estLimE) & (estLimS<=sdata(:,2)) & (sdata(:,2)<=estLimN) ;
            sdata = sdata(idx,:);
            sk = unique([sk;sdata],'rows');
        end
        if inclVoronoi
            [vx,vy] = voronoi(sdata(:,1),sdata(:,2));
            sv = unique([vx(:) vy(:)],'rows');
            idx = (estLimW<=sv(:,1)) & (sv(:,1)<=estLimE) & (estLimS<=sv(:,2)) & (sv(:,2)<=estLimN) ;
            sv = sv(idx,:);
            sk = unique([sk;sv],'rows');
        end
            sk = [sk,ones(size(sk,1),1)*estTime];
    %-----------------End: Copied from Original codes------------        
    end
    
        

    % Create coordinate matrix
    rawCoord = [rawX,rawY,rawT];

    % Set coordinates for hard data and soft data
    ch = rawCoord(rawType == 0,:);
    cs1 = rawCoord(rawType == 1,:);
    cs2 = rawCoord(rawType == 2,:);
    %cs3 = rawCoord(rawType == 3,:); %--------- P Jat (Triangular pdf data)
    %cs4 = rawCoord(rawType == 4,:); %----------p Jat (Truncated Gaussian pdf)

    % Calculate mean interpolation
    if flgRemvMean
        mstI=stmeaninterpstv([sptlX,sptlY],tempG',sptlM,tempM',rawCoord);
    end

    % Set hard data values
    if flgLog
        val = rawVal1(rawType == 0,:);
        val(val<=0) = minVal;
        zh = log(val);
    else
        zh = rawVal1(rawType == 0,:);
    end
    % Create mean trend removed value
    if flgRemvMean
        zh = zh -mstI(rawType == 0,:);
    end

    % Set soft data values (Uniform)
    if flgLog
        lowLimi = rawVal1(rawType == 1,:);
        upLimi = rawVal2(rawType == 1,:);
        uniVal = (lowLimi + upLimi)/2;
        nZeroLow = lowLimi(lowLimi<=0,:);
        nZeroUp = upLimi(lowLimi<=0,:);
        if length(upLimi(lowLimi<=0,:)) > 0
            upLimi(lowLimi<=0,:) = minVal + (nZeroUp - nZeroLow);
            lowLimi(lowLimi<=0,:) = minVal;
        end
        zlow = log(lowLimi);
        zup = log(upLimi);
        uniVal = log(uniVal);
    else
        zlow = rawVal1(rawType == 1,:);
        zup = rawVal2(rawType == 1,:);
        uniVal = (zlow+zup)/2;
    end
    % Create mean trend removed value
    if flgRemvMean
        zlow = zlow - mstI(rawType == 1,:);
        zup = zup - mstI(rawType == 1,:);
        uniVal = uniVal - mstI(rawType == 1,:);
    end
    % Create soft data (Uniform)
    [stype1,nl1,limi1,probdens1]=probaUniform(zlow,zup);

    % Set soft data values (Gaussian)
    if flgLog
        rmean = rawVal1(rawType == 2,:);
        rstd = rawVal2(rawType == 2,:);
        rvar = rstd.^2;
        zvar = log(1.+(rvar./rmean.^2));
        zmean = log(rmean)-(zvar.^2)/2;
    else
        zmean = rawVal1(rawType == 2,:);
        zstd = rawVal2(rawType == 2,:);
        zvar = zstd.^2
    end
    % Create mean trend removed value
    if flgRemvMean
        zmean = zmean - mstI(rawType == 2,:);
    end
    % Create soft data (Gaussian)
    [stype2,nl2,limi2,probdens2]=probaGaussian(zmean,zvar);

     %----------------------soft type ==3 (P Jat)--------------------------
        % Set soft data values (Triangular)
%     if flgLog
%         rmean = rawVal1(rawType == 3,:);
%         rstd = rawVal2(rawType == 3,:);
%         rvar = rstd.^2;
%         zvar = log(1.+(rvar./rmean.^2));
%         zmean = log(rmean)-(zvar.^2)/2;
%     else
%         zmean = rawVal1(rawType == 2,:);
%         zstd = rawVal2(rawType == 2,:);
%         zvar = zstd.^2
%     end
%     % Create mean trend removed value
%     if flgRemvMean
%         zmean = zmean - mstI(rawType == 2,:);
%     end
%     % Create soft data (Gaussian)
%     [stype2,nl2,limi2,probdens2]=probaGaussian(zmean,zvar);
    
    %--------------------End:soft type ==3 (P Jat)-------------------------

    
     %----------------------soft type ==4 (P Jat)--------------------------
        % Set soft data values (Truncated Gaussian)
%     if flgLog
%         rmean = rawVal1(rawType == 4,:);
%         rstd = rawVal2(rawType == 4,:);
%         rvar = rstd.^2;
%         zvar = log(1.+(rvar./rmean.^2));
%         zmean = log(rmean)-(zvar.^2)/2;
%     else
%         zmean = rawVal1(rawType == 2,:);
%         zstd = rawVal2(rawType == 2,:);
%         zvar = zstd.^2
%     end
%     % Create mean trend removed value
%     if flgRemvMean
%         zmean = zmean - mstI(rawType == 2,:);
%     end
%     % Create soft data (Gaussian)
%     [stype2,nl2,limi2,probdens2]=probaGaussian(zmean,zvar);
    
    %--------------------End:soft type ==4 (P Jat)-------------------------
    
    
    %Concatenate soft data
    if (size(cs1,1) == 0) & (size(cs2,1) == 0)
        cs = []
        stype = 2;
        nl=[];
        limi=[];
        probdens=[];
    elseif (size(cs1,1) == 0) & (size(cs2,1) ~= 0)
        cs = cs2;
        stype = stype2;
        nl = nl2;
        limi = limi2;
        probdens = probdens2;
    elseif (size(cs1,1) ~= 0) & (size(cs2,1) == 0)
        cs = cs1;
        stype = stype1;
        nl = nl1;
        limi = limi1;
        probdens = probdens1;
    else
        cs = [cs1;cs2];
        [stype,nl,limi,probdens]=probacat(stype1,nl1,limi1,probdens1,...
                                      stype2,nl2,limi2,probdens2);
    end

%     %---------------- For extended soft data type : P Jat -----------------
%        %Concatenate soft data
%     if (size(cs1,1) == 0) & (size(cs2,1) == 0) & (size(cs3,1) == 0) & (size(cs4,1) == 0)
%         cs = []
%         stype = 2;
%         nl=[];
%         limi=[];
%         probdens=[];
%     elseif (size(cs1,1) ~= 0) & (size(cs2,1) == 0)& (size(cs3,1) == 0) & (size(cs4,1) == 0)
%         cs = cs1;
%         stype = stype1;
%         nl = nl1;
%         limi = limi1;
%         probdens = probdens1;
%     elseif (size(cs1,1) == 0) & (size(cs2,1) ~= 0)& (size(cs3,1) == 0) & (size(cs4,1) == 0)
%         cs = cs2;
%         stype = stype2;
%         nl = nl2;
%         limi = limi2;
%         probdens = probdens2;
%         
%     elseif (size(cs1,1) == 0) & (size(cs2,1) == 0)& (size(cs3,1) ~= 0) & (size(cs4,1) == 0)
%         cs = cs3;
%         stype = stype3;
%         nl = nl2;
%         limi = limi3;
%         probdens = probdens3;
%     elseif (size(cs1,1) == 0) & (size(cs2,1) == 0)& (size(cs3,1) == 0) & (size(cs4,1) ~= 0)
%         cs = cs4;
%         stype = stype4;
%         nl = nl4;
%         limi = limi4;
%         probdens = probdens4;        
%     else
%         cs = [cs1;cs2;cs3;cs4];
%         [stype,nl,limi,probdens]=probacat(stype1,nl1,limi1,probdens1,...
%                                       stype2,nl2,limi2,probdens2,...
%                                       stype3,nl3,limi3,probdens3,...
%                                       stype4,nl4,limi4,probdens4);
%     end 
%    %---------------End: For extended soft data type : P Jat --------------- 
    
    
    
        
    
	% Dummy
	exponentialC([1 2],[1 2]);
	gaussianC([1 2],[1 2]);
	sphericalC([1 2],[1 2]);
	holesinC([1 2],[1 2]);
	holecosC([1 2],[1 2]);   
    % Combine duplicated data
    [chC,zhC,csC,stypeC,nlC,limiC,probdensC] = combinedupli(ch,zh,'ave',cs,stype,nl,limi,probdens);
	% Calculate BME moments
     existID2 = exist('stdPathRT.txt', 'file');
     if (existID2==2)
          pTolerance=0.01;
          load riverReaches;  % saved by 'calcCov(): Line 71
          load riverTopology; % saved by 'calcCov(): Line 71
          
          % Below line is fixed so it can be saved and retrived to speed up bmeEst 
          % Save when fist bmeEst() is called and delete file we calcCov() is called
          [c1rawR,c2rawR]=cartesian2riverProj(riverReaches,chC,pTolerance);
          chC =c1rawR;
          
          dist = {'coord2distRiver' [riverTopology]};
          % Combine duplicated data
          [chC,zhC,csC,stypeC,nlC,limiC,probdensC] = combinedupli(chC,zhC,'ave',csC,stypeC,nlC,limiC,probdensC);  
          [moments,info]=BMEprobaMomentsRiver(sk,chC,csC,zhC,stypeC,nlC,...
              limiC,probdensC,covmodel,covparam,nhmax,nsmax,dmax,order,dist);           
     else
          [moments,info]=BMEprobaMomentsRiver(sk,chC,csC,zhC,stypeC,nlC,...
              limiC,probdensC,covmodel,covparam,nhmax,nsmax,dmax,order); % only 14 input arguments
     end

    % Output the result
    estMean = moments(:,1);
    estVar = moments(:,2);
    save estMean;
    locNan = [];
    if sum(isnan(estMean)) == length(estMean)
        flgNan = true;
        locNan = [sk(isnan(estMean),1),sk(isnan(estMean),2)];
        estVar(isnan(estMean)) = sill;
        estMean(isnan(estMean)) = mean([zh;uniVal;zmean]);
    elseif sum(isnan(estMean)) ~= 0
        flgNan = true;
        locNan = [sk(isnan(estMean),1),sk(isnan(estMean),2)];
        estVar(isnan(estMean)) = sill;
        estMean(isnan(estMean)) = mean(estMean(~isnan(estMean)));
    end
    if length(locNan) ~= 0
        dlmwrite(outFile3, locNan,'delimiter',',','precision','%12.10g');
    end        

    if flgRemvMean
        if size(sk,2)>3
            sk1 = [sk(:,1:2), sk(:,5)]; % in case of River
        else
            sk1=sk;
        end
        mk = stmeaninterpstv([sptlX,sptlY],tempG',sptlM,tempM',sk1);
        estMean = estMean + mk;
    end
    dlmwrite(outFile1, [sk(:,1),sk(:,2),estMean,estVar],'delimiter',',','precision','%12.10g');
% % % -----------Original Code ---------------------------------------------
% % %     % Create smoothing point
% % %     [smX,smY] = meshgrid(min(sk(:,1)):(max(sk(:,1))-min(sk(:,1)))/(numDispX-1):max(sk(:,1)),...
% % %                          min(sk(:,2)):(max(sk(:,2))-min(sk(:,2)))/(numDispY-1):max(sk(:,2)));
% % %     smMean = griddata(sk(:,1),sk(:,2),estMean,smX(:),smY(:),'linear',{'QJ'});    
% % %     smVar = griddata(sk(:,1),sk(:,2),estVar,smX(:),smY(:),'linear',{'QJ'});
% % %======================================================================
    if (existID2==2)
        smXX = [min(sk(:,1)):(max(sk(:,1))-min(sk(:,1)))/(numDispX-1):max(sk(:,1))]';
        smYY = [min(sk(:,2)):(max(sk(:,2))-min(sk(:,2)))/(numDispY-1):max(sk(:,2))]';
        XYGridMean  = getXYGridData(smXX, smYY, sk,estMean,estMean);
        XYGridVar    = getXYGridData(smXX, smYY, sk,estVar,estVar);
        smX         = XYGridMean(:,1);
        smY         = XYGridMean(:,2);
        smMean      = XYGridMean(:,3);
        smVar       = XYGridVar(:,3);    
        
    else
        % Create smoothing point
        [smX,smY] = meshgrid(min(sk(:,1)):(max(sk(:,1))-min(sk(:,1)))/(numDispX-1):max(sk(:,1)),...
                         min(sk(:,2)):(max(sk(:,2))-min(sk(:,2)))/(numDispY-1):max(sk(:,2)));
        smMean = griddata(sk(:,1),sk(:,2),estMean,smX(:),smY(:),'linear',{'QJ'});    
        smVar = griddata(sk(:,1),sk(:,2),estVar,smX(:),smY(:),'linear',{'QJ'});
    end        
               
    dlmwrite(outFile2, [smX(:),smY(:),smMean,smVar],'delimiter',',','precision','%12.10g');
    disp('BME estimation done!');
catch
    error('bmeEst function failed')
    
end
