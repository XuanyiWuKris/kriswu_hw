%this function links particles from their position file. exports a
%centers_tracked.txt file that contains frame, particle id, x, y, r and
%edge status. If it is an annulus, it also exports the unwarped positions

function particleTrack(directory,imname, boundaryType, frameidind, verbose, particleTrackToggle)

% 
% directory = '/eno/cllee3/DATA/240506/testsorting/';
% %topDirectory = '/Users/carmenlee/Desktop/20150731reprocesseduniaxial/'
% % %topDirectory = './DATA/test/Step09/'
% imname = '200Hz*.tif'; %image format and regex
% frameidind = 16;
% particleTrackToggle = true
% %
% 
% boundaryType = "annulus"; %if airtable use "airtable" if annulus use "annulus"
% radiusRange = [40, 57];
% %radiusRange = [45, 78]; %airtable
% 
% verbose = true;

%handling specific file structure stuff
if boundaryType == "annulus"
    directorydata = [directory, 'particles/'];
    datafiles = dir([directorydata, imname(1:end-4),'warped_centers.txt']);
else
    %datafiles = dir([directory, imname(1:end-4),'_centers.txt'])
    directorydata = [directory,'particles/']
    [directorydata, imname(1:end-4), 'centers.txt']
    datafiles = dir([directorydata, imname(1:end-4), 'centers.txt'])
end

dtol=10;

%find guess for array size
posData = load([directorydata, datafiles(1).name]);
nFrames = length(datafiles);    
skipamount = length(posData); %I chose this as a result of my system size, could and should be altered based on your specific system and variability in finding particles
centers = nan(nFrames*skipamount, 6);
if boundaryType == "airtable"
    for frame = 1:nFrames
        frame
        %posData = dlmread([directory, datafiles(n).name]);
    
        posData = load([directorydata, datafiles(frame).name]);
        frameid = frame
        %frameid = str2double(datafiles(frame).name(frameidind:frameidind+3));
        %posData = new;
        frameNumber = ones(length(posData),1)*frameid;
        id = 1:length(posData);
        
        %posArray = [posArray; [posData(:,1), posData(:,2),  frameNumber]];
        
        centers((frame-1)*skipamount+1:(frame-1)*skipamount +length(posData),:) = [frameNumber, id', posData(:,1), posData(:,2), posData(:,3), posData(:,4)];
        
        %x = extractfield(posData, 'x')'; %for using Ephraim's already detected particles
        %y = extractfield(posData, 'y')';
        %r = (extractfield(posData, 'r'))';
%         lpos = min(x-r);
%         rpos = max(x+r);
%         upos = max(y+r);
%         bpos = min(y-r);
%         edges = zeros(length(r), 1);
%         for k= 1:length(x)
%             if x(k)-r(k) <=lpos+dtol
%                 edges(k) = -1;
%             elseif x(k)+r(k) >=rpos-dtol
%                 edges(k) = 1;
%             elseif y(k)+r(k) >= upos-dtol
%                 edges(k) = 2;
%             elseif y(k)-r(k) <= bpos+dtol
%                 edges(k) = -2;
%             end
%         end
        %centers((frame-1)*skipamount+1:(frame-1)*skipamount+length(x)+1) = [frameNumber, id', x, y, round(r), edges];
    end
else
    for frame = 1:nFrames
        frame
        posData = readmatrix([directorydata, datafiles(frame).name]);
    
        %posData = load([directory, datafiles(n).name]);
        
        frameid = str2double(datafiles(frame).name(frameidind:frameidind+3));
        
        frameNumber = ones(length(posData),1)*frameid;
        id = 1:length(posData);
        %posArray = [posArray; [posData(:,1), posData(:,2),  frameNumber]];
        
        centers((frame-1)*skipamount+1:(frame-1)*skipamount +length(posData),:) = [frameNumber, id', posData(:,1), posData(:,2), posData(:,3), posData(:,4)];
    end
end


%tidying up the centers dataframe
centers(any(isnan(centers),2),:)=[];
posArray=[centers(:,3), centers(:,4), centers(:,1)];

%%uncomment this if you don't care about particle order
%if particleTrackToggle == false

out = fopen([directory,'centers_trackedunsrt.txt'],'w');
fprintf(out,['frame', ',', 'particleID', ',', 'x' ',' 'y', ',','r',',','edge''\n']);
fclose(out);
dlmwrite([directory,'centers_trackedunsrt.txt'], centers, 'delimiter',',','-append');

%else
%linking the particles, where we remember the particles over 50 frames, iin
%2 dimensions, limit is 30 pixels of motion per frame
param = struct('mem', 50, 'good', 0,'dim',2,'quiet',0);
linked = track(posArray, 30, param);


%%
%swap the old indices for the tracked indices


neworder = nan(length(posArray),6);
start = 1;
for f = 1:nFrames %note that we're splitting the data by frame number because it isn't guaranteed that particles won't be found in the exact same position, frame to frame
    frameid = str2double(datafiles(f).name(frameidind:frameidind+3));
    ind = find(linked(:,3) == frameid);
    xy = linked(ind,:);
    xy = sortrows(xy, [1,2]); %
    
    ind2 = find(centers(:,1) == frameid);
    slice = centers(ind2,:);
    sortedslice = sortrows(slice, [3,4]);
    
    sortedslice(:,2) = xy(:,4);
    len = size(sortedslice,1)
    %spot = neworder(start:size(sortedslice)(1)+start-1,:)
    neworder(start:len+start-1,:)=sortedslice;
    start = start+ length(sortedslice);
end
neworder(any(isnan(neworder),2),:)=[];
neworder =sortrows(neworder,[1,2]);
dif= sortrows(neworder(:,3)) - sortrows(centers(:,3))

out = fopen([directory,'centers_tracked.txt'],'w');
fprintf(out,['frame', ',', 'particleID', ',', 'x' ',' 'y', ',','r',',','edge''\n']);
fclose(out);
dlmwrite([directory,'centers_tracked.txt'], neworder, 'delimiter',',','-append');

%exports original positions
if boundaryType == "annulus"
    rearrange2 = neworder;
    x = neworder(:,3);
    y = neworder(:,4);

    midx = 6304; %size of image
    [theta,r] = cart2pol(x-midx/2,y-midx/2);

    d = -6.5*r.^2/(200*(925+6.5)); %6.5 is the thickness of the particles in mm, 925 is distance between particles and camera lens in mm
    
    s1 = d+r;
    [ut,vt] = pol2cart(theta,s1);
    ut = ut + midx/2;
    vt = vt + midx/2;

    ifcn = @(c) [ut(:) vt(:)];
    tform = geometricTransform2d(ifcn);
    [uv] = transformPointsInverse(tform, [0,0]); %particle original coordinates
    u = uv(:,1)-400;
    v = uv(:,2)-400;

    rearrange2(:,3) = u;
    rearrange2(:,4) = v;

    out = fopen([directory,'centers_tracked_original.txt'],'w');
    fprintf(out,['frame', ',', 'particleID', ',', 'x' ',' 'y', ',','r',',','edge''\n']);
    fclose(out);
    dlmwrite([directory,'centers_tracked_original.txt'], rearrange2, 'delimiter',',','-append');

    
% %% 
end
% 

end
%   exit
%if you want to see the particle traces
%if verbose
%     figure;
%     image = dir([directory,'warpedimg/', imname(1:end-4),'warped.tif']);
%     pic = imread([directory, 'warpedimg/', image(1).name]);
%     img =imshow(pic);
%     hold on;
%     N = unique(neworder(:,2));
%     cm = colormap(parula(size(N,1))); 
%     for frame = 1:length(N)
%         ind = find(neworder(:,2) ==frame);
%         plot(neworder(ind,3), neworder(ind,4),'Color',cm(frame,:));
%         hold on;
%     end
%     savefig(img, [directory, 'traces.png'])
    %imwrite(img, )
%end
