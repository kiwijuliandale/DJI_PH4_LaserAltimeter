function [handles]=meas_width(handles)
%measure widths function

I1P=handles.I1P;
if I1P==1
f = 25;                     %focal length
fc = 24.851372;             %corrected focal length
PPA = [0.203089;-0.087931]; %difference between matlab centre and photo centre
k1 = -9.1303e-005;          %radial offsets
k2 = 8.4284e-007;
k3 = -3.7862e-009;
p1 = -3.1598e-005;          %centre offsets
p2 = 2.0922e-005;
b1 = 7.0190e-004;           %other offsets
b2 = -1.4177e-004;

else
                    
fc = 24.851372;             %focal length
PPA = [0.203089;-0.087931]; %difference between matlab centre and photo centre
k1 = 0;          %radial offsets
k2 = 0;
k3 = 0;
p1 = 0;          %centre offsets
p2 = 0;
b1 = 0;           %other offsets
b2 = 0;
end
set(handles.text9,'String','Click to indicate endpoints on whale, use right-click to zoom.')
rect=handles.rect;
H=handles.H;
TL=handles.TL;
hold on
[x1,y1,butt]=ginput(1);

if butt==3; %if right click zoom in on point
    
    
    xlim([x1-500, x1+500])
    ylim([y1-375, y1+375])
    [x1,y1,butt]=ginput(1);
    plot(x1,y1,'Marker','x','Color','g','LineStyle','none','MarkerSize',8,'LineWidth',2)
    xlim([rect(1), rect(1)+rect(3)])
    ylim([rect(2), rect(2)+rect(4)])
    
elseif butt==1
    plot(x1,y1,'Marker','x','Color','g','LineStyle','none','MarkerSize',8,'LineWidth',2)
else
end


if ~isempty(butt) %if enter is pressed at any point the function leaves the field for this width empty
    
    [x2,y2,butt]=ginput(1);
    if butt==3; %if right click zoom in on point
        
        xlim([x2-500, x2+500])
        ylim([y2-375, y2+375])
        [x2,y2,butt]=ginput(1);
        plot(x2,y2,'Marker','x','Color','g','LineStyle','none','MarkerSize',8,'LineWidth',2)
        
    elseif butt==1
        plot(x2,y2,'Marker','x','Color','g','LineStyle','none','MarkerSize',8,'LineWidth',2)
    else
    end
    plot([x1,x2],[y1,y2],'LineStyle','-','Color','g')
    xlim([rect(1), rect(1)+rect(3)])
    ylim([rect(2), rect(2)+rect(4)])
    
    if ~isempty(butt)
        
        xlim([rect(1), rect(1)+rect(3)])
        ylim([rect(2), rect(2)+rect(4)])
        P1 = [(x1-.5)-4608/2; 3456/2-(y1-.5)]*0.003758; %calculate pixel indices
        P2 = [(x2-.5)-4608/2; 3456/2-(y2-.5)]*0.003758; %calculate pixel indices
        T1 = P1;
        T2 = P2;
        xmes = T1(1);
        ymes = T1(2);
        xp = PPA(1);
        yp = PPA(2);
        x = xmes-xp;
        y = ymes-yp;
        r = sqrt(x^2+y^2);
        dr = k1*r^3+k2*r^5+k3*r^7;
        T1c(1,1) = xmes-xp+x*dr/r+p1*(r^2+2*x^2)+2*p2*x*y+b1*x+b2*y; %corrected pixel indices for first loc
        T1c(2,1) = ymes-yp+y*dr/r+p2*(r^2+2*y^2)+2*p1*x*y;
        xmes = T2(1);
        ymes = T2(2);
        xp = PPA(1);
        yp = PPA(2);
        x = xmes-xp;
        y = ymes-yp;
        r = sqrt(x^2+y^2);
        dr = k1*r^3+k2*r^5+k3*r^7;
        T2c(1,1) = xmes-xp+x*dr/r+p1*(r^2+2*x^2)+2*p2*x*y+b1*x+b2*y; %corrected pixel indices for 2nd loc
        T2c(2,1) = ymes-yp+y*dr/r+p2*(r^2+2*y^2)+2*p1*x*y;
        Dc = sqrt((T2c-T1c)'*(T2c-T1c))*H/fc;
        W=Dc;
        if H==1
            W=W/TL*100; %if lidar height was not given scale the width to be a percentage of the total length
            set(handles.text8, 'String', strjoin({'Width (%TL):', num2str(W)})); %print width under image
        else
            set(handles.text8, 'String', strjoin({'Width (m):', num2str(W)})); %print width under image
        end
    else
        W=[];
    end
else
    W=[];
end



xlim([rect(1), rect(1)+rect(3)])
ylim([rect(2), rect(2)+rect(4)])
hold off
% updata handles with width

handles.W=W;
end