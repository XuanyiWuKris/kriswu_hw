function [centers, radii, metrics] = AlecParticleFind(Rimg,wallMask,RS,RL,NsmallH,NlargeH)


    %Detect large and small particles with generous sensitivity
    [centersL,radiiL,metricL] = imfindcircles(Rimg,[RL-3 RL+3],'objectpolarity','bright','sensitivity',0.945,'method','twostage','EdgeThreshold',0.02);
    [centersS,radiiS,metricS] = imfindcircles(Rimg,[RS-2 RS+2],'objectpolarity','bright','sensitivity',0.945,'method','twostage','EdgeThreshold',0.02);
    fprintf('imfindcircles initially detected %d large particles\n',length(centersL))
    fprintf('imfindcircles initially detected %d small particles\n',length(centersS))

    %Number of particles detected
    Nlarge=length(centersL); Nsmall=length(centersS);
    Idlarge=1:Nlarge; Idsmall=1:Nsmall;

    %Remove any small or large particle whose perimeter lies on the
    %toothed ring
    n = 1;
    while n <= Nsmall && Nsmall > NsmallH
        x = centersS(n,1);
        y = centersS(n,2);
        r = 0.67 * radiiS(n);
 
    
        for theta = linspace(0,2*pi)
            x_test = round(x + r * cos(theta));
            y_test = round(y + r * sin(theta));
    
            if wallMask(y_test, x_test) == 0
                centersS(n,:)=[];radiiS(n)=[];metricS(n)=[];Idsmall(n)=[];
                Nsmall=Nsmall-1;
                n=n-1;
                break
            end
        end
        n=n+1;
    end

    n=1;
    while n <= Nlarge && Nlarge > NlargeH
        x=centersL(n,1);
        y=centersL(n,2);
        r = 0.67 * radiiL(n);

        for theta = linspace(0,2*pi)
            x_test=round(x+r*cos(theta));
            y_test=round(y+r*sin(theta));

            if wallMask(y_test,x_test)==0
                centersL(n,:)=[];radiiL(n)=[];metricL(n)=[];Idlarge(n)=[];
                Nlarge=Nlarge-1;
                n=n-1;
                break;
            end
        end
        n=n+1;
    end

    fprintf('%d large particles remaining after removing particles on boundary\n',Nlarge)
    fprintf('%d small particles remaining after removing particles on boundary\n',Nsmall)

    
    %If two small particles are overlapping by more than 20% of a small
    %particle radius, remove the particle with lower metric
    n=1;
    while n <= Nsmall && Nsmall > NsmallH
        x1=centersS(n,1);
        y1=centersS(n,2);
        r1=radiiS(n);
        m1=metricS(n);
        j=n+1;
        while j<=Nsmall
            x2=centersS(j,1);
            y2=centersS(j,2);
            r2=radiiS(j);
            m2=metricS(j);
            if (sqrt((x1-x2)^2+(y1-y2)^2))<(0.5*r1+r2)
                if(m1<m2)
                    centersS(n,:)=[];radiiS(n)=[];metricS(n)=[];Idsmall(n)=[];
                    Nsmall=Nsmall-1;
                    n=n-1;
                    break
                else
                    centersS(j,:)=[];radiiS(j)=[];metricS(j)=[];Idsmall(j)=[];
                    Nsmall=Nsmall-1;
                    j=j-1;
                end
             end
            j=j+1;
        end
        n=n+1;
    end

    fprintf('%d small particles remaining after removing overlapping small particles\n',Nsmall)

    %If two large particlces are overlapping by 20% of large radius,
    %remove the one that is less circular (lower metric)
    n=1;
    while n <= Nlarge && Nlarge > NlargeH
        x1=centersL(n,1);
        y1=centersL(n,2);
        m1=metricL(n);
        j=n+1;
        while j<=Nlarge
            x2=centersL(j,1);
            y2=centersL(j,2);
            m2=metricL(j);
            if sqrt((x1-x2)^2+(y1-y2)^2)<((2*RL)-(.3*RL))
                if(m1<m2)
                    centersL(n,:)=[];radiiL(n)=[];metricL(n)=[];Idlarge(n)=[];
                    Nlarge=Nlarge-1;
                    n=n-1;
                    break
                else
                    centersL(j,:)=[];radiiL(j)=[];metricL(j)=[];Idlarge(j)=[];
                    Nlarge=Nlarge-1;
                    j=j-1;
                end
             end
            j=j+1;
        end
        n=n+1;
    end

    fprintf('%d large particles remaining after removing overlapping large particles\n',Nlarge)

    %If a large particle is enclosing multiple small particles at this
    %point it can't be a real particle
    n=1;
    while n <= Nlarge && Nlarge > NlargeH
        x1=centersL(n,1);
        y1=centersL(n,2);
        r1=radiiL(n);
        m1=metricL(n);
        j=1;
        numParticlesPartialEnclosed=0;
        numParticlesFullyEnclosed=0;
        while j<=Nsmall
            x2=centersS(j,1);
            y2=centersS(j,2);
            r2=radiiS(j);
            m2=metricS(j);
            if sqrt((x1-x2)^2+(y1-y2)^2) < r1+0.5*r2 && m2>1.25*m1
                numParticlesPartialEnclosed=numParticlesPartialEnclosed+1;
            end
            if sqrt((x1-x2)^2+(y1-y2)^2) < r1-0.8*r2 && m2>1.25*m1
                numParticlesFullyEnclosed=numParticlesFullyEnclosed+1;
            end
            j=j+1;
        end
        if numParticlesPartialEnclosed>1
            centersL(n,:)=[];radiiL(n)=[];metricL(n)=[];Idlarge(n)=[];
            Nlarge=Nlarge-1;
            n=n-1;
        elseif numParticlesFullyEnclosed>0
            centersL(n,:)=[];radiiL(n)=[];metricL(n)=[];Idlarge(n)=[];
            Nlarge=Nlarge-1;
            n=n-1;
        end
        n=n+1;
    end

    
    %Remove small particles detections that are inside large particles
    n=1;
    while n <= Nsmall && Nsmall > NsmallH
        x1=centersS(n,1);
        y1=centersS(n,2);
        m1=metricS(n);
        j=1;
        while j<=Nlarge
            x2=centersL(j,1);
            y2=centersL(j,2);
            m2=metricL(j);
            if sqrt((x1-x2)^2+(y1-y2)^2)<RL-0.75*RS && m1<2*m2
                    centersS(n,:)=[];radiiS(n)=[];metricS(n)=[];Idsmall(n)=[];
                    Nsmall=Nsmall-1;
                    n=n-1;
                    break
            end
            j=j+1;
        end
        n=n+1;
    end
    

    fprintf('%d large particles remaining after removing large particles overlapping small\n',Nlarge)
    fprintf('%d small particles remaining after removing small particles inside large\n',Nsmall);


    %Remove small particle false positive detections that are sitting in
    %empty
    %voids/';;''''''''''''lkk;';'///////////';';/;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    n=1;
    while n <= Nsmall && Nsmall > NsmallH
        x1=centersS(n,1);
        y1=centersS(n,2);
        m1=metricS(n);
        j=1;
        numLargeOverlap=0;
        numSmallOverlap=0;
        while j<=Nlarge
            x2=centersL(j,1);
            y2=centersL(j,2);
            m2=metricL(j);
            if sqrt((x1-x2)^2+(y1-y2)^2)<(RL+0.5*RS) && m1<m2
                numLargeOverlap=numLargeOverlap+1;
            end
            if sqrt((x1-x2)^2+(y1-y2)^2)<(RL+0.8*RS) && m1<m2
                numSmallOverlap=numSmallOverlap+1;
            end
            if numLargeOverlap>0 || numLargeOverlap+numSmallOverlap>1
                centersS(n,:)=[];radiiS(n)=[];metricS(n)=[];Idsmall(n)=[];
                    Nsmall=Nsmall-1;
                    n=n-1;
                    break
            end
            j=j+1;
        end
        %{
        k=1;
        while k<=Nsmall
            x3=particleS(k).x;
            y3=particleS(k).y;
            m3=particleS(k).metric;
            if sqrt((x1-x3)^2+(y1-y3)^2)<(RS+0.6*RS) && m1<m3
                numSmallOverlap=numSmallOverlap+1;
            end
            if numLargeOverlap>0 || numLargeOverlap+numSmallOverlap>1
                centersS(n,:)=[];radiiS(n)=[];metricS(n)=[];
                    Nsmall=Nsmall-1;
                    n=n-1;
                    break
            end
            k=k+1;
        end
        %}
        n=n+1;
    end

    fprintf('%d small particles remaining after removing small particles overlapping large\n',Nsmall)

    %If a particle has less than 1 neighbor, remove it
    n=1;
    while n <= Nsmall && Nsmall > NsmallH
        x1=centersS(n,1);
        y1=centersS(n,2);
        id1=Idsmall(n);
        j=1;
        z=0;
        while j<=Nsmall
            x2=centersS(j,1);
            y2=centersS(j,2);
            id2=Idsmall(j);
            if sqrt((x1-x2)^2+(y1-y2)^2)<((2*RS)+(0.20*RS)) && id1~=id2
                z=z+1;
            end
            j=j+1;
        end
        i=1;
        while i<=Nlarge
            x2=centersL(i,1);
            y2=centersL(i,2);
            if sqrt((x1-x2)^2+(y1-y2)^2)<((RS+RL)+(0.20*RL))
                z=z+1;
            end
            i=i+1;
        end
        if z<1
            centersS(n,:)=[];radiiS(n)=[];metricS(n)=[];Idsmall(n)=[];
            Nsmall=Nsmall-1;
            n=n-1;
        end
        n=n+1;
    end
    n=1;
    while n <= Nlarge && Nlarge > NlargeH
        x1=centersL(n,1);
        y1=centersL(n,2);
        id1=Idlarge(n);
        j=1;
        z=0;
        while j<=Nlarge
            x2=centersL(j,1);
            y2=centersL(j,2);
            id2=Idlarge(j);
            if sqrt((x1-x2)^2+(y1-y2)^2)<((2*RL)+(0.20*RL)) && id1~=id2
                z=z+1;
            end
            j=j+1;
        end
        i=1;
        while i<=Nsmall
            x2=centersS(i,1);
            y2=centersS(i,2);
            if sqrt((x1-x2)^2+(y1-y2)^2)<((RS+RL)+(0.20*RL))
                z=z+1;
            end
            i=i+1;
        end
        if z<1
            centersL(n,:)=[];radiiL(n)=[];metricL(n)=[];Idlarge(n)=[];
            Nlarge=Nlarge-1;
            n=n-1;
        end
        n=n+1;
    end

    fprintf('%d large particles remaining after trimming isolated particles\n',Nlarge)
    fprintf('%d small particles remaining after trimming isolated particles\n',Nsmall)


    %Combine large and small particles into a single struct
    centers=[centersL; centersS]; radii=[radiiL; radiiS]; metrics=[metricL; metricS];

end


