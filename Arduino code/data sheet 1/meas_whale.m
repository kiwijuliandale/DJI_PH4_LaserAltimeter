function [handles]=meas_whale(handles,hObject)

%allows user to indicate points along axis of whale with ginput
%updates handles to be used in Whalength.m with total whale length

H=handles.H;

set(handles.text8, 'String', '   ')

%Define constants for lens corrections - constants and calculations by Pascal Sirguey
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
fc = 24.851372;                     %focal length

PPA = [0.203089;-0.087931]; %difference between matlab centre and photo centre
k1 = 0;          %radial offsets
k2 = 0;
k3 = 0;
p1 = 0;          %centre offsets
p2 = 0;
b1 = 0;           %other offsets
b2 = 0;

end
w=0;
ct=1;
X=[];
Y=[];


set(handles.text9,'String','Use the mouse to drag a rectangle over whale to be measured')
rect=getrect;
handles.rect=rect;

set(handles.text9,'String','Start from rostrum. Right-click to zoom, Left-click to add points. Press ENTER when finished adding points')


while w==0             %clicking points along the whale with the mouse, breaks when ENTER is pressed
    
    xlim([rect(1), rect(1)+rect(3)])
    ylim([rect(2), rect(2)+rect(4)])
    
    hold on
    plot(X,Y,'LineStyle','-','Color','r','Marker','x')
    [x1,y1,butt]=ginput(1);
    
    if butt==3; %if right click zoom in on point
        
        plot(X,Y,'LineStyle','-','Color','r','Marker','x')
        xlim([x1-500, x1+500])
        ylim([y1-375, y1+375])
        [x2,y2,butt]=ginput(1);
        
        X(ct)=x2;
        Y(ct)=y2;
        
        
        ct=ct+1;
    elseif isempty(butt)
        break
    else
        X(ct)=x1;
        Y(ct)=y1;
        ct=ct+1;
    end
    
end

xlim([rect(1), rect(1)+rect(3)])
ylim([rect(2), rect(2)+rect(4)])
set(handles.text9,'String','Measure any widths then check Image Qualities are set for this image.')

lvind=find(X==min(X)); %left value index
rvind=find(X==max(X)); %right
bvind=find(Y==min(Y)); %top
tvind=find(Y==max(Y)); %bottom
if max(Y)-min(Y)>max(X)-min(X) %if whale is oriented vertically in image

    if bvind>tvind %if nose is pointing up
        tvind=2;
    else
        bvind=2;
    end
    %smoothing
slm = slmengine(Y(2:end)',X(2:end)','leftvalue',X(bvind),'rightvalue',X(tvind),'knots',3);

guidata(hObject,handles)

for n1=1:length(Y)-1;
    
    yf((n1-1)*30+1:n1*30)=linspace(Y(n1),Y(n1+1),30)';
    
end

xf=[linspace(X(1),X(2),30), slmeval(yf(31:end),slm)];
plot(xf, yf, 'm')
PP=[(xf-.5)-4608/2; 3456/2-(yf-.5)]*0.003758; %calculate pixel indices
else
    
    if lvind>rvind
        rvind=2;
    else
        lvind=2;
    end

%smoothing
slm = slmengine(X(2:end)',Y(2:end)','leftvalue',Y(lvind),'rightvalue',Y(rvind),'knots',3);

guidata(hObject,handles)

for n1=1:length(X)-1;
    
    xf((n1-1)*30+1:n1*30)=linspace(X(n1),X(n1+1),30)';
    
end

yf=[linspace(Y(1),Y(2),30), slmeval(xf(31:end),slm)];
plot(xf, yf, 'm')
PP=[(xf-.5)-4608/2; 3456/2-(yf-.5)]*0.003758; %calculate pixel indices
end

T1 = PP(:,1:end-1);
T2 = PP(:,2:end);
%calculate corrected  length
xmes = T1(1,:);
ymes = T1(2,:);
xp = PPA(1);
yp = PPA(2);
x = xmes-xp;
y = ymes-yp;
r = sqrt(x.^2+y.^2);
dr = k1*r.^3+k2*r.^5+k3*r.^7;
T1c = [xmes-xp+x.*dr./r+p1*(r.^2+2*x.^2)+2*p2*x.*y+b1*x+b2*y; ymes-yp+y.*dr./r+p2*(r.^2+2*y.^2)+2*p1*x.*y]; %corrected pixel indices for first loc

xmes = T2(1,:);
ymes = T2(2,:);
xp = PPA(1);
yp = PPA(2);
x = xmes-xp;
y = ymes-yp;
r = sqrt(x.^2+y.^2);
dr = k1*r.^3+k2*r.^5+k3*r.^7;
T2c = [xmes-xp+x.*dr./r+p1*(r.^2+2*x.^2)+2*p2*x.*y+b1*x+b2*y; ymes-yp+y.*dr./r+p2*(r.^2+2*y.^2)+2*p1*x.*y]; %corrected pixel indices for 2nd loc

Dc = sqrt((T2c(1,:)-T1c(1,:)).*(T2c(1,:)-T1c(1,:))+(T2c(2,:)-T1c(2,:)).*(T2c(2,:)-T1c(2,:)))*H/fc;    %corrected length over ground(sea): to be stored in excel file somhow

Lcum=zeros(1,length(Dc));
Lcum(1)=Dc(1);

for nn=2:length(Dc);
    Lcum(nn)=Dc(nn)+Lcum(nn-1);
end

Lvec=[xf; yf; Lcum, 0];
TL=Lcum(end);
handles.TL=TL;
handles.Lvec=Lvec;

if H==1
    set(handles.text8, 'String', 'TL (no lidar height)'); %print length under image
else
    set(handles.text8, 'String', strjoin({'Length (m):', num2str(TL)})); %print length under image
end


guidata(hObject,handles)

end