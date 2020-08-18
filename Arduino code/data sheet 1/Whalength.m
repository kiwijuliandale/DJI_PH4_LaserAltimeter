function varargout = Whalength(varargin)
% WHALENGTH MATLAB code for Whalength.fig WINDOWS VERSION
%      WHALENGTH, by itself, creates a new WHALENGTH or raises the existing
%      singleton*.
%
%      H = WHALENGTH returns the handle to a new WHALENGTH or the handle to
%      the existing singleton*.
%
%      WHALENGTH('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WHALENGTH.M with the given input arguments.
%
%      WHALENGTH('Property','Value',...) creates a new WHALENGTH or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Whalength_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Whalength_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%   Eva Leunissen
%   eva.leunissen@gmail.com

% Last Modified by GUIDE v2.5 19-Jul-2017 14:39:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Whalength_OpeningFcn, ...
    'gui_OutputFcn',  @Whalength_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Whalength is made visible.
function Whalength_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Whalength (see VARARGIN)

% Choose default output for Whalength
CF=cd; %current directory
handles.output = hObject;
handles.oldpath=[];
handles.xfile=[];
handles.fnsh=[];
handles.Sing_im=[];
handles.H=[];
handles.theta=0;
sheet=1; %define default excel sheet to be sheet 1
handles.sheet=sheet;
set(handles.text7, 'String', '    ')
set(handles.text6, 'String', '    ')
sharp=1;
water='Calm'; %define state of water to be 'Calm' by default, unless it is changed with the radio button to 'Ruffled'
flukes='straight';
sides='N';
unotes=[];
try
    load(fullfile([CF '\' 'I1P.mat']))
catch
    I1P=0;
end
handles.I1P=I1P;
set(handles.checkbox4,'Value',I1P)
try
    load(fullfile([CF '\' 'Offset.mat']))
catch
    CLoffset=0;
end
handles.CLoffset=CLoffset;
set(handles.text32,'String',{'Offset:';CLoffset})
handles.CF=CF;
save(fullfile([CF '\' 'Imquals.mat']),'sharp','water','flukes','sides','unotes')
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Whalength wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Whalength_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
% Choose default command line output for trialgui
handles.output = hObject;


guidata(hObject, handles);


% --- Executes on button press in pushbutton1. select folder
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ds = uigetdir(cd,'Select folder for a day of images...'); %cd starts in current folder

set(handles.text10, 'String', '    ') %clear previous displayed filename for output excel file
set(handles.text6, 'String', '    ') 
pathd = ds;
handles.pathd=pathd;                  %store day folder directory in 'path' in handles structure
fname=strsplit(pathd,'\\');

handles.dayfd=fname{end};
set(handles.text7,'String',fname(end))

handles.bestim_ind=1; %setting starting index for images and subfolders to 1 by default, will de different if an image to start from instead is entered.
handles.subf_ind=1;
guidata(hObject,handles)  % Save the handles structure.
uiresume(gcbf)

% --- Executes on button press in pushbutton2. Load excel file
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    oldpath = handles.pathd;    %get previous file path
catch
    oldpath = [];
end
if~isempty(oldpath)
    fds=strsplit(oldpath,'\\');
    ll=length(fds{end});
    oldpath=oldpath(1:end-ll-1); %create path to folder which contains day folder ie one step back from pathd
    handles.oldpath=oldpath;
    [xfile,pathx] = uigetfile(fullfile(oldpath,'*.xlsx'),'Select excel file...');
else
    [xfile,pathx] = uigetfile(fullfile('*.xlsx'),'Select excel file...');
end

set(handles.text6,'String',xfile)
handles.pathx=pathx;
handles.xfile=xfile;

sheet=handles.sheet;
[ndata, text, alldata] = xlsread(fullfile(pathx,xfile),sheet);
handles.xcelall=alldata;            % 'alldata' contains the spreadsheet as a cells structure, with a cell
                                    % for each entry, annd contains Nan if excel cell was empty
handles.xceln=ndata;

pathd=handles.pathd;       %get path of folder for each day of images

subdirs = regexp(genpath(pathd),['[^;]*'],'match'); %get names of subdirectories within day folder - these will not all be true image folders
n_subs=length(subdirs);       % number of subfolders in day folder, not all of these entries are actually proper image folders
cc=1;
for ind=1:n_subs;       %for each subdirectory:
    
    files = dir(fullfile(subdirs{ind},'*.jpg'));               %get jpg filenames in source directory
    
    if ~isempty(files)              %if there are image files in this subfolder...
        
        imdirs{cc}=subdirs{ind};     %...store the directory of this subfolder in imdirs structure
        
        ims{cc}=files;               %store image names in ims structure
        
        cc=cc+1;                      %counter
        
    else
        
    end
end
handles.cc=cc;
ff=1; %counter

for nf=2:size(alldata,1); %For each cell under the heading 'Folder':
    
    if isnan(alldata{nf,1})==0; %if cell does not contain NaN...
        subfolders{ff}=alldata{nf,1};    %store folder name in 'subfolders' structure
        nfind(ff)=nf;                    %store cell row number in nfind
        ff=ff+1;
        
    else
    end
end
%store best image names (with notes and lidar heights) from excel file with corresp subfolder name, may
%include 'NaN's for blank spaces in excel sheet but will deal with that
%later

for ni=1:length(nfind);
    if ni~=length(nfind)  %for all but the last image
        bestims{ni,1}=ndata(nfind(ni)-1:nfind(ni+1)-2,1);
        notes{ni,1}=text(nfind(ni):nfind(ni+1)-1,3);
        tilt{ni,1}=ndata(nfind(ni)-1:nfind(ni+1)-2,6); %read values for tilt (or NaN if not provided) from column I
        heights{ni,1}=ndata(nfind(ni)-1:nfind(ni+1)-2,7); %read 5s median lidar heigh from column J
    else
        bestims{ni,1}=ndata(nfind(ni)-1:end,1);
        notes{ni,1}=text(nfind(ni):end,3);
        tilt{ni,1}=ndata(nfind(ni)-1:end,6);
        heights{ni,1}=ndata(nfind(ni)-1:end,7);
    end
end
handles.bestims=bestims;
handles.subfolders=subfolders;
handles.imdirs=imdirs;
handles.bestims=bestims;
handles.ims=ims;
handles.tilt=tilt;
handles.heights=heights;
handles.notes=notes;
guidata(hObject,handles)            % Save the handles structure.





% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% RUN button
CF=handles.CF;
if ~isempty(handles.xfile) && ~isempty(handles.oldpath)
    
    oops=0; %is set to zero each time an image is loaded and is changed only when 'Redo image' button is pressed and sets oops to 1
    save(fullfile([CF '\' 'oops.mat']),'oops')
    set(handles.text8, 'String', '   ');
    set(handles.text10, 'String', '   ')
    fnsh=0;
    save(fullfile([CF '\' 'fnsh.mat']),'fnsh');
    
    pad='0000';             %to be used to construct image names
    clear A
    %Defining output excel file headers for each column
    A{1,5}='Image quality';
    A{1,12}='Body width along body axis at 10% increments';
    A{1,28}='Body width along body axis at 5% increments';
    A{2,1}='Whale ID';
    A{2,2}='Image date';
    A{2,3}='Image time';
    A{2,4}='Filename';
    A{2,5}='Image sharpness (1-4)';
    A{2,6}='Flukes up? (@surface/straight/drooped)';
    A{2,7}='Water (calm/ruffled)';
    A{2,8}='Sides clear? (Y/N)';
    A{2,9}='Tilt (degrees)';
    A{2,10}='Corrected height (m)';
    A{2,11}='Total Length (m)';
    A{2,12}='Width at 10% TL';
    A{2,13}='Width at 20% TL';
    A{2,14}='Width at 30% TL';
    A{2,15}='Width at 40% TL';
    A{2,16}='Width at 50% TL';
    A{2,17}='Width at 60% TL';
    A{2,18}='Width at 70% TL';
    A{2,19}='Width at 80% TL';
    A{2,20}='Width at 90% TL';
    A{2,21}='Width @ eye';
    A{2,22}='Rostrum-eye';
    A{2,23}='Rostrum-BH';
    A{2,24}='Fluke width';
    A{2,25}='Folder';
    A{2,26}='Label (for mult.whales per image)';
    A{2,27}='Notes';
    A{2,28}='Width at 5% TL';
    A{2,29}='Width at 10% TL';
    A{2,30}='Width at 15% TL';
    A{2,31}='Width at 20% TL';
    A{2,32}='Width at 25% TL';
    A{2,33}='Width at 30% TL';
    A{2,34}='Width at 35% TL';
    A{2,35}='Width at 40% TL';
    A{2,36}='Width at 45% TL';
    A{2,37}='Width at 50% TL';
    A{2,38}='Width at 55% TL';
    A{2,39}='Width at 60% TL';
    A{2,40}='Width at 65% TL';
    A{2,41}='Width at 70% TL';
    A{2,42}='Width at 75% TL';
    A{2,43}='Width at 80% TL';
    A{2,44}='Width at 85% TL';
    A{2,45}='Width at 90% TL';
    A{2,46}='Width at 95% TL';
    
    handles.A=A;
    save(fullfile([CF '\' 'A.mat']),'A') %first time A is saved
    count=3;
    save(fullfile([CF '\' 'count.mat']),'count')
    handles.count=count;
    subf_ind=handles.subf_ind;
    bestim_ind=handles.bestim_ind;
    cc=handles.cc;
    subfolders=handles.subfolders;
    imdirs=handles.imdirs;
    bestims=handles.bestims;
    ims=handles.ims;
    tilt=handles.tilt;
    heights=handles.heights;
    notes=handles.notes;
    
    %read image files within each subfolder and check that the folder name in
    %the excel sheet matches that in the directories in imdirs
    for ind=subf_ind:cc-1;
        load(fullfile([CF '\' 'fnsh.mat']))
        if fnsh==1;
            break
        else
        end
        
        
        if ~isempty(strfind(imdirs{ind},subfolders{ind})) %if the folder name in the excel sheet matches the name in the directory...
            set(handles.text13, 'String', '   ')
            for ind2=bestim_ind:length(bestims{ind})+1 %for each of the best images in the subfolder
                load(fullfile([CF '\' 'count.mat']))
     
                if ind2==length(bestims{ind})+1
                    break
                else
                end
                
                oops=0; %is set to zero each time an image is loaded and is changed only when 'Redo image' button s pressed and sets oops to 1
                save(fullfile([CF '\' 'oops.mat']),'oops')
                load(fullfile([CF '\' 'fnsh.mat']))
                if fnsh==1;
                    break
                else
                end
                
                set(handles.checkbox3,'Value',0)
                set(handles.edit4,'String','Edit text')
                unotes=[];
                save(fullfile([CF '\' 'Imquals.mat']),'unotes','-append')
                if isnan(bestims{ind}(ind2))==0 %and if it is not a blank cell
                    bin=num2str(bestims{ind}(ind2));
                    l=length(bin); %number of 'numbers' in best image, ie 16 has 2 numbers
                    imnum=strcat(pad(1:end-l),bin); %4-number image number
                 
                    imcell=struct2cell(ims{ind}(end,1));
                    
                    imnameS=imcell{1}; %sample image name in this subfolder
                    imname=strcat(imnameS(1:end-8),imnum,'.JPG'); %starts from 3rd character as standard folder of images also contains imge names that start with .- or something
                    
                    listing=dir(fullfile([imdirs{ind} '\' imname]));
                    dattims=strsplit(listing.date);
                    
                    handles.curr_im_dir=[imdirs{ind} '\' imname];
                    C = imread([imdirs{ind} '\' imname]);   %read the image
                    handles.C=C;
                    handles.dattims=dattims;
                    
                    set(handles.text4, 'String', imname(1:end-4));              %show image name above image in GUI
                    set(handles.text5, 'String', strcat('Notes: ', cell2mat(notes{ind}(ind2))));   %show any notes above image
                    theta=tilt{ind}(ind2); %tilt angle in degress, NaN if not provided
                    if isnan(theta)==1
                        theta=0;            % if theta not provided, assume tilt is zero
                    else
                    end
                    handles.theta=theta;
                    CLoffset=handles.CLoffset;
                    H=(heights{ind}(ind2)*cos(theta*pi/180)+CLoffset)/100;       %lidar height, read from excel sheet, corrected for tilt and offset of camera height relative to lidar (1.5cm below lidar) and converted to metres
                    handles.H=H;
                    handles.subfolder=subfolders{ind};
                    hold off
                    image(C);
                    xlim([0.5 4608.5])
                    ylim([0.5 3456.5])
                    axis equal                      %makes image square
                    axis off
                    
                    if isnan(H) | H==1;
                        H=1;
                        handles.H=H;
                        handles=meas_whale(handles,hObject);
                        load(fullfile([CF '\' 'A.mat']),'A')
                        load(fullfile([CF '\' 'count.mat']),'count')
                        handles.A=A; %updates A in handles after measuring
                        
                        handles.count=count;
                        TL=handles.TL;
                        subfolder=handles.subfolder;
                       
                        A{count,2}=dattims{1};
                        A{count,3}=dattims{2};
                        A{count,9}=theta;
                        A{count,10}='N/A';
                        A{count,25}=subfolder;
                        A{count,4}=get(handles.text4,'String');
                        A{count,11}='TL';
                        
                        save(fullfile([CF '\' 'A.mat']),'A')
                        handles.A=A;
                        
                        guidata(hObject,handles)
                        
                    else
                        
                        handles=meas_whale(handles,hObject);
                        
                        load(fullfile([CF '\' 'A.mat']),'A')
                        load(fullfile([CF '\' 'count.mat']),'count')
                        handles.A=A; %updates A in handles after measuring
                        
                        handles.count=count;
                        TL=handles.TL;
                        subfolder=handles.subfolder;
                        
                        A{count,2}=dattims{1};
                        A{count,3}=dattims{2};
                        A{count,9}=theta;
                        A{count,10}=H;
                        A{count,25}=subfolder;
                        A{count,4}=get(handles.text4,'String');
                        A{count,11}=TL;
                        
                        save(fullfile([CF '\' 'A.mat']),'A')
                        handles.A=A;
                        
                        guidata(hObject,handles)
                        
                    end
                    
                    waitfor(handles.checkbox3,'Value'); %waits for 'Correct?' checkbox to be ticked so image properties are set before moving on to next whale or image
                    load(fullfile([CF '\' 'A.mat']))
                    load(fullfile([CF '\' 'Imquals.mat']))
                    drawnow()
                    A{count,5}=sharp;
                    A{count,7}=water;
                    A{count,6}=flukes;
                    A{count,8}=sides;
                    A{count,27}=unotes;
                    dayfd=handles.dayfd;
                    path=handles.pathd;
                    filename = strcat(dayfd, ' lengths.xlsx');
                    xlswrite(fullfile([path '\' filename]),A)
                    
                    count=count+1;
                    handles.count=count;
                    save(fullfile([CF '\' 'A.mat']),'A')
                    save(fullfile([CF '\' 'count.mat']),'count')
                    set(handles.text9,'String','If more whales to measure in this picture click "Measure another whale". If finished with this image click "Next image"')
                    
                    uiwait(gcf) %waits for either 'next image' button or 'measure another whale' button or 'redo' button
                    load(fullfile([CF '\' 'oops.mat']))
                    while oops==1; %if the redo image button was pressed enter this while loop
                        set(handles.checkbox3,'Value',0)
                        set(handles.edit4,'String','Edit text')
                        unotes=[];
                        save(fullfile([CF '\' 'Imquals.mat']),'unotes','-append')
                        oops=0; %reset oops to zero
                        save(fullfile([CF '\' 'oops.mat']),'oops')

                        count=count-1; %reduce counter by one
                        save(fullfile([CF '\' 'count.mat']),'count')
                        
                        image(C);
                        axis equal                      %makes image square
                        axis off
                        xlim([0.5 4608.5])
                        ylim([0.5 3456.5])
                        
                        if isnan(H) | H==1;
                            H=1;
                            handles.H=H;
                            handles=meas_whale(handles,hObject);
                            load(fullfile([CF '\' 'A.mat']),'A')
                            load(fullfile([CF '\' 'count.mat']),'count')
                            handles.A=A; %updates A in handles after measuring
                            
                            handles.count=count;
                            TL=handles.TL;
                            subfolder=handles.subfolder;
                            
                            A{count,2}=dattims{1};
                            A{count,3}=dattims{2};
                            A{count,9}=theta;
                            A{count,10}='N/A';
                            A{count,25}=subfolder;
                            A{count,4}=get(handles.text4,'String');
                            A{count,11}='TL';
                            
                            save(fullfile([CF '\' 'A.mat']),'A')
                            handles.A=A;
                            
                            guidata(hObject,handles)
                            
                        else
                            
                            handles=meas_whale(handles,hObject);
                            
                            load(fullfile([CF '\' 'A.mat']),'A')
                            load(fullfile([CF '\' 'count.mat']),'count')
                            handles.A=A; %updates A in handles after measuring
                            
                            handles.count=count;
                            TL=handles.TL;
                            subfolder=handles.subfolder;
                            
                            A{count,2}=dattims{1};
                            A{count,3}=dattims{2};
                            A{count,9}=theta;
                            A{count,10}=H;
                            A{count,25}=subfolder;
                            A{count,4}=get(handles.text4,'String');
                            A{count,11}=TL;
                            
                            save(fullfile([CF '\' 'A.mat']),'A')
                            handles.A=A;
                             
                            guidata(hObject,handles)
                            
                        end
                        
                        waitfor(handles.checkbox3,'Value'); %waits for 'Correct?' checkbox to be ticked so image properties are set before moving on to next whale or image
                        load(fullfile([CF '\' 'A.mat']))
                        load(fullfile([CF '\' 'Imquals.mat']))
                        drawnow()
                        A{count,5}=sharp;
                        A{count,7}=water;
                        A{count,6}=flukes;
                        A{count,8}=sides;
                        A{count,27}=unotes;
                        
                        count=count+1;
                        handles.count=count;
                        
                        dayfd=handles.dayfd;
                        path=handles.pathd;
                        filename = strcat(dayfd, ' lengths.xlsx');
                        xlswrite(fullfile([path '\' filename]),A)
                        save(fullfile([CF '\' 'A.mat']),'A')
                        save(fullfile([CF '\' 'count.mat']),'count')
                        set(handles.text9,'String','If more whales to measure in this picture click "Measure another whale". If finished with this image click "Next image"')
                        
                        uiwait(gcf) %waits for either 'next image' button or 'measure another whale' button or 'redo' button
                        load(fullfile([CF '\' 'oops.mat']))
                        
                    end
                    
                    if ind==cc-1 && ind2==length(bestims{ind});
                        set(handles.text4, 'String', strjoin({imname(1:end-4), ' (Last image for this Folder)'}));
                    else
                    end
                    
                    
                else
                end
                
            end
        else
            set(handles.text13, 'String', 'Make sure sheet number is correct')
        end
    end
else
    set(handles.text13, 'String', 'Please load image folder and excel file')
end
guidata(hObject,handles)





% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%'NEXT IMAGE' button - allows for-loop processing best images to continue
set(handles.text8, 'String', '    ')

guidata(hObject,handles)
uiresume(gcbf)



function edit1_Callback(hObject, eventdata, handles) %input sheet number
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
sheet=str2double(get(hObject,'String'));
handles.sheet=sheet;
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 'MEASURE ANOTHER WHALE' button - runs calculation code again if measuring more than one whale per picture
CF=handles.CF;
set(handles.checkbox3,'Value',0)
set(handles.edit4,'String','Edit text')
unotes=[];
save(fullfile([CF '\' 'Imquals.mat']),'unotes','-append')
C=handles.C;

image(C);
xlim([0.5 4608.5])
ylim([0.5 3456.5])
axis equal                      %makes image square
axis off
Lbl = inputdlg({'Identifier'},'Give label for whale just measured...', [1 60]);

load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'count.mat']))

A{count-1,26}=Lbl{1};

subfolder=handles.subfolder;
%TL=handles.TL;
theta=handles.theta;
H=handles.H;
dattims=handles.dattims;

if H==1;
    
    handles=meas_whale(handles,hObject);
    
    A{count,2}=dattims{1};
    A{count,3}=dattims{2};
    A{count,9}=theta;
    A{count,10}='N/A';
    A{count,25}=subfolder;
    A{count,4}=get(handles.text4,'String');
    A{count,11}='TL';
    
    guidata(hObject,handles)
    
else
    
    handles=meas_whale(handles,hObject);
    
    A{count,2}=dattims{1};
    A{count,3}=dattims{2};
    A{count,9}=theta;
    A{count,10}=H;
    A{count,25}=subfolder;
    A{count,4}=get(handles.text4,'String');
    A{count,11}=handles.TL;
end
save(fullfile([CF '\' 'A.mat']),'A')
waitfor(handles.checkbox3,'Value'); %waits for 'Correct?' checkbox to be ticked so image properties are set before moving on to next whale or image

load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'Imquals.mat']))

A{count,5}=sharp;
A{count,7}=water;
A{count,6}=flukes;
A{count,8}=sides;
A{count,27}=unotes;

Lbl = inputdlg({'Identifier'},'Give label for whale just measured...', [1 60]);
A{count,26}=Lbl{1};
dayfd=handles.dayfd;
path=handles.pathd;
filename = strcat(dayfd, ' lengths.xlsx');
xlswrite(fullfile([path '\' filename]),A)
save(fullfile([CF '\' 'A.mat']),'A')
count=count+1;
save(fullfile([CF '\' 'count.mat']),'count');

set(handles.text9,'String','If more whales to measure in this picture click "Measure another whale". If finished with this image click "Next image"')

uiwait(gcf) %wait for either next image or redo button
load(fullfile([CF '\' 'oops.mat']))
while oops==1; %if the redo image button was pressed enter this while loop
    set(handles.checkbox3,'Value',0)
    set(handles.edit4,'String','Edit text')
    unotes=[];
    save(fullfile([CF '\' 'Imquals.mat']),'unotes','-append')
    oops=0; %reset oops to zero
    save(fullfile([CF '\' 'oops.mat']),'oops')

    count=count-1; %reduce counter by one
    save(fullfile([CF '\' 'count.mat']),'count')
    
    image(C);
    axis equal                      %makes image square
    axis off
    xlim([0.5 4608.5])
    ylim([0.5 3456.5])
    
    if isnan(H) | H==1;
        H=1;
        handles.H=H;
        handles=meas_whale(handles,hObject);
        load(fullfile([CF '\' 'A.mat']),'A')
        load(fullfile([CF '\' 'count.mat']),'count')
        handles.A=A; %updates A in handles after measuring
        
        handles.count=count;
        TL=handles.TL;
        subfolder=handles.subfolder;
        
        A{count,2}=dattims{1};
        A{count,3}=dattims{2};
        A{count,9}=theta;
        A{count,10}='N/A';
        A{count,25}=subfolder;
        A{count,4}=get(handles.text4,'String');
        A{count,11}='TL';
       
        save(fullfile([CF '\' 'A.mat']),'A')
        handles.A=A;
       
        guidata(hObject,handles)
        
    else
        
        handles=meas_whale(handles,hObject);
        
        load(fullfile([CF '\' 'A.mat']),'A')
        load(fullfile([CF '\' 'count.mat']),'count')
        handles.A=A; %updates A in handles after measuring
        
        handles.count=count;
        TL=handles.TL;
        subfolder=handles.subfolder;
        
        A{count,2}=dattims{1};
        A{count,3}=dattims{2};
        A{count,9}=theta;
        A{count,10}=H;
        A{count,25}=subfolder;
        A{count,4}=get(handles.text4,'String');
        A{count,11}=TL;
       
        save(fullfile([CF '\' 'A.mat']),'A')
        handles.A=A;
        
        guidata(hObject,handles)
        
    end
    
    waitfor(handles.checkbox3,'Value'); %waits for 'Correct?' checkbox to be ticked so image properties are set before moving on to next whale or image
    load(fullfile([CF '\' 'A.mat']))
    load(fullfile([CF '\' 'Imquals.mat']))
    drawnow()
    A{count,5}=sharp;
    A{count,7}=water;
    A{count,6}=flukes;
    A{count,8}=sides;
    A{count,27}=unotes;
   
    count=count+1;
    handles.count=count;
    dayfd=handles.dayfd;
    path=handles.pathd;
    filename = strcat(dayfd, ' lengths.xlsx');
    xlswrite(fullfile([path '\' filename]),A)
    save(fullfile([CF '\' 'A.mat']),'A')
    save(fullfile([CF '\' 'count.mat']),'count')
    set(handles.text9,'String','If more whales to measure in this picture click "Measure another whale". If finished with this image click "Next image"')
    
    uiwait(gcf) %waits for either 'next image' button or 'measure another whale' button or 'redo' button
    load(fullfile([CF '\' 'oops.mat']))
    
end

guidata(hObject,handles)
uiresume(gcbf)




% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%'FINISH' button
%Saves A as excel file in same folder as day image folder
CF=handles.CF;
load(fullfile([CF '\' 'A.mat']),'A')

dayfd=handles.dayfd;
path=handles.pathd;
filename = strcat(dayfd, ' lengths.xlsx');
xlswrite(fullfile([path '\' filename]),A)
set(handles.text10, 'String', filename)
set(handles.pushbutton6, 'Value', 1)
fnsh=1;
save(fullfile([CF '\' 'fnsh.mat']),'fnsh')
set(handles.edit5,'String','Edit text')

guidata(gcbf,handles)
uiresume(gcbf)


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%MEASURE AT 10%TL button

%Define constants - constants and calculations by Pascal Sirguey
CF=handles.CF;
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

TL=handles.TL;
Lvec=handles.Lvec;
rect=handles.rect;
H=handles.H;
pct10TL=[0.1:0.1:0.9]*TL;
TLvec=Lvec(3,1:end);
xvec=Lvec(1,1:end-1);
yvec=Lvec(2,1:end-1);
pct10ws=zeros(1,9);

set(handles.text9,'String','Click where lines meet edge of whale, use right-click to zoom. Press ENTER to skip a measurement.')

for ind=1:length(pct10TL);
    % xlim([rect(1), rect(1)+rect(3)])
    % ylim([rect(2), rect(2)+rect(4)])
    ind10pct=find(TLvec>pct10TL(ind),1,'first');
    ind10pctv{ind}=ind10pct;
    %calculating perpendicular lines to clicked line segments on whale
    x1=xvec(ind10pct);
    y1=yvec(ind10pct);
    x0=xvec(ind10pct-1);
    y0=yvec(ind10pct-1);
    x2=xvec(ind10pct+1);
    y2=yvec(ind10pct+1);
    
    l=400; %length of one half of guideline
    m=(y2-y0)/(x2-x0); %gradient of length segment that 5% point is found on
    if m==0; %if the line segment is perfectly straight the inverse gradient is infinite!
        
        xg=[x1, x1];
        yg=[y1+l, y1-l];
        
    else
        mp=-1/m; %perpendicular gradient
        
        cp=y1-mp*x1; %intercept value of perp line
        
        %solving for plotting coordinates of ends of guideline
        a=1+mp^2;
        b=2*mp*cp-2*x1-2*y1*mp;
        c=cp^2+x1^2-2*y1*cp+y1^2-l^2;
        
        xg(1)=(-1*b+sqrt(b^2-4*a*c))/(2*a);
        xg(2)=(-1*b-sqrt(b^2-4*a*c))/(2*a);
        yg=mp*xg+cp;
        
    end
    % xv1=linspace(x1,xg(1),500);
    % yv1=mp*xv1+cp; %vector of points along one side of perpendicular line
    % xv2=linspace(x1,xg(2),500);
    % yv2=mp*xv2+cp; %vector of points along other side of perpendicular line
    % C=handles.C;
    hold on
    plot(x1,y1,'Marker','x','Color','b','LineStyle','none','MarkerSize',8,'LineWidth',2)
    
    plot(xg,yg,'LineStyle','-','Color','y')
    xlim([x1-500, x1+500])
    ylim([y1-500, y1+500])
    
    [xw1, yw1, butt]=ginput(1);
    
    if butt==3; %if right click zoom in on point
        
        xlim([xw1-300, xw1+300])
        ylim([yw1-300, yw1+300])
        [xw1,yw1,butt]=ginput(1);
        plot(xw1,yw1,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
        xlim([x1-500, x1+500])
        ylim([y1-500, y1+500])
        
    elseif butt==1
        plot(xw1,yw1,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
        
    else
        continue
    end
  
    [xw2, yw2, butt]=ginput(1);
    if butt==3; %if right click zoom in on point
        
        xlim([xw2-300, xw2+300])
        ylim([yw2-300, yw2+300])
        [xw2,yw2,butt]=ginput(1);
        plot(xw2,yw2,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
        xlim([x1-500, x1+500])
        ylim([y1-500, y1+500])
        
    elseif butt==1
        plot(xw2,yw2,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
    else
        continue
    end

    P1 = [(xw1-.5)-4608/2; 3456/2-(yw1-.5)]*0.003758; %calculate pixel indices
    P2 = [(xw2-.5)-4608/2; 3456/2-(yw2-.5)]*0.003758; %calculate pixel indices
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
    pct10ws(ind)=Dc; %stores width at each 5% interval
    if H==1;
        pct10ws(ind)=pct10ws(ind)*100/TL;
        set(handles.text8, 'String', strjoin({'Width (%TL):', num2str(pct10ws(ind))})); %print length under image
    else
        set(handles.text8, 'String', strjoin({'Width (m):', num2str(Dc)})); %print length under image
    end
    
    
    
end
xlim([rect(1), rect(1)+rect(3)])
ylim([rect(2), rect(2)+rect(4)])
hold off

% updata data storage cell, A
load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'count.mat']))

A(count,12:20)=num2cell(pct10ws);
save(fullfile([CF '\' 'A.mat']),'A')
set(handles.text9,'String','Measure widths, then set image qualities for this image then check "Correct?"')

guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function text4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in popupmenu1. define image sharpness
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
CF=handles.CF;
sharp=get(hObject,'Value');
save(fullfile([CF '\' 'Imquals.mat']),'sharp','-append')

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox1 - No longer used!.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

guidata(gcbf,handles)


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% SIDES CLEAR?
% Hint: get(hObject,'Value') returns toggle state of checkbox2
CF=handles.CF;
if (get(hObject,'Value') == get(hObject,'Max'))
    sides='Y';
else
    sides='N';
end
save(fullfile([CF '\' 'Imquals.mat']),'sides','-append')

guidata(gcbf,handles)

% --- Executes during object creation, after setting all properties.
function uipanel7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function uipanel7_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1
% eventdata  structure with the following fields (see UIBUTTONGROUP)

% handles    structure with handles and user data (see GUIDATA)
CF=handles.CF;
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton1'
        water='Calm';
    case 'radiobutton2'
        water='Ruffled';
end

save(fullfile([CF '\' 'Imquals.mat']),'water','-append')

guidata(hObject,handles)



% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% CORRECT?
% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on button press in pushbutton8: WIDTH @ EYE.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
CF=handles.CF;
[handles]=meas_width(handles);
W=handles.W;
load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'count.mat']))

A{count,21}=W;
save(fullfile([CF '\' 'A.mat']),'A')

% --- Executes on button press in pushbutton9: FLUKE WIDTH.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
CF=handles.CF;
[handles]=meas_width(handles);
W=handles.W;
load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'count.mat']))

A{count,24}=W;
save(fullfile([CF '\' 'A.mat']),'A')

% --- Executes on button press in pushbutton10: BLOSTRUM - BH.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
CF=handles.CF;
[handles]=meas_width(handles);
W=handles.W;
load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'count.mat']))

A{count,23}=W;
save(fullfile([CF '\' 'A.mat']),'A')

% --- Executes on button press in pushbutton11: ROSTRUM - EYE.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

CF=handles.CF;
[handles]=meas_width(handles);
W=handles.W;
load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'count.mat']))

A{count,22}=W;
save(fullfile([CF '\' 'A.mat']),'A')


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2
CF=handles.CF;
contents = cellstr(get(hObject,'String'));
flukes=contents{get(hObject,'Value')};
save(fullfile([CF '\' 'Imquals.mat']),'flukes','-append')


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton12 - START OVER.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
CF=handles.CF;
oops=1;
save(fullfile([CF '\' 'oops.mat']),'oops')
uiresume(gcbf)


% --- Executes on button press in pushbutton13 - SELECT SINGLE IMAGE.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
CF=handles.CF;
try
    oldpath = handles.pathd;    %get previous file path
catch
    oldpath = [];
end
if~isempty(oldpath)
    fds=strsplit(oldpath,'\\');

    ll=length(fds{end});
    oldpath=oldpath(1:end-ll-1); %create path to folder which contains day folder ie one step back from pathd
    handles.oldpath=oldpath;
    [Sing_im,pathim] = uigetfile(fullfile(oldpath,'*.JPG'),'Select image...');
else
    [Sing_im,pathim] = uigetfile(fullfile('*.JPG'),'Select image...');
end

set(handles.text23,'String',Sing_im)
handles.pathd=pathim;
handles.subfolder=pathim;
handles.Sing_im=Sing_im;
handles.dayfd=Sing_im;
guidata(hObject,handles)            % Save the handles structure.



function edit2_Callback(hObject, eventdata, handles) %single image lidar height input
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
H=str2double(get(hObject,'String'));
handles.H=H;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton14 - GO: run single image analysis.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
CF=handles.CF;
if ~isempty(handles.Sing_im) && ~isempty(handles.H)
    set(handles.text25, 'String', '    ')
   
    set(handles.text8, 'String', '   ');
    set(handles.text10, 'String', '   ')
    
    pathim=handles.pathd;
    Sing_im=handles.Sing_im;
   
    clear A
    %Defining output excel file headers for each column
    A{1,5}='Image quality';
    A{1,12}='Body width along body axis at 10% increments';
    A{1,28}='Body width along body axis at 5% increments';
    A{2,1}='Whale ID';
    A{2,2}='Image date';
    A{2,3}='Image time';
    A{2,4}='Filename';
    A{2,5}='Image sharpness (1-4)';
    A{2,6}='Flukes up? (@surface, straight, drooped)';
    A{2,7}='Water (calm, ruffled)';
    A{2,8}='Sides clear? (Y/N)';
    A{2,9}='Tilt (degrees)';
    A{2,10}='Corrected height (m)';
    A{2,11}='Total Length (m)';
    A{2,12}='Width at 10% TL';
    A{2,13}='Width at 20% TL';
    A{2,14}='Width at 30% TL';
    A{2,15}='Width at 40% TL';
    A{2,16}='Width at 50% TL';
    A{2,17}='Width at 60% TL';
    A{2,18}='Width at 70% TL';
    A{2,19}='Width at 80% TL';
    A{2,20}='Width at 90% TL';
    A{2,21}='Width @ eye';
    A{2,22}='Rostrum-eye';
    A{2,23}='Rostrum-BH';
    A{2,24}='Fluke width';
    A{2,25}='Folder';
    A{2,26}='Label (for mult.whales per image)';
    A{2,27}='Notes';
    A{2,28}='Width at 5% TL';
    A{2,29}='Width at 10% TL';
    A{2,30}='Width at 15% TL';
    A{2,31}='Width at 20% TL';
    A{2,32}='Width at 25% TL';
    A{2,33}='Width at 30% TL';
    A{2,34}='Width at 35% TL';
    A{2,35}='Width at 40% TL';
    A{2,36}='Width at 45% TL';
    A{2,37}='Width at 50% TL';
    A{2,38}='Width at 55% TL';
    A{2,39}='Width at 60% TL';
    A{2,40}='Width at 65% TL';
    A{2,41}='Width at 70% TL';
    A{2,42}='Width at 75% TL';
    A{2,43}='Width at 80% TL';
    A{2,44}='Width at 85% TL';
    A{2,45}='Width at 90% TL';
    A{2,46}='Width at 95% TL';
    
    handles.A=A;
    save(fullfile([CF '\' 'A.mat']),'A') %first time A is saved
    count=3;
    save(fullfile([CF '\' 'count.mat']),'count')
    handles.count=count;
    
    set(handles.text13, 'String', '   ')
    
    load(fullfile([CF '\' 'count.mat']))
   
    set(handles.checkbox3,'Value',0)
    set(handles.edit4,'String','Edit text')
    unotes=[];
    save(fullfile([CF '\' 'Imquals.mat']),'unotes','-append')
    
    listing=dir(fullfile([pathim '\' Sing_im]));
    dattims=strsplit(listing.date);
    
    C = imread([pathim '\' Sing_im]);   %read the image
    handles.C=C;
    handles.dattims=dattims;
    
    set(handles.text4, 'String', Sing_im(1:end-4));              %show image name above image in GUI
    
    theta=handles.theta; %tilt angle from user input
        if isnan(theta)==1
           theta=0;            % if theta not provided, assume tilt is zero
        else
        end
    H=handles.H;       %lidar height from user input
    CLoffset=handles.CLoffset;
    H=H*cos(theta*pi/180)+CLoffset/100; %H corrected for tilt and camera offset relative to lidar, in metres
    handles.H=H;
    hold off
    image(C);
    xlim([0.5 4608.5])
    ylim([0.5 3456.5])
    axis equal                      %makes image square
    axis off
    
    if H==0 | isnan(H);
        load(fullfile([CF '\' 'A.mat']),'A')
        load(fullfile([CF '\' 'count.mat']),'count')
        H=1;
        handles.H=H;
        handles=meas_whale(handles,hObject);
        
        handles.A=A; %updates A in handles after measuring
        
        handles.count=count;
        
        A{count,2}=dattims{1};
        A{count,3}=dattims{2};
        A{count,9}=theta;
        A{count,10}='N/A';
        A{count,25}=pathim;
        A{count,4}=Sing_im;
        A{count,11}='TL';
        
        save(fullfile([CF '\' 'A.mat']),'A')
        handles.A=A;
        
        guidata(hObject,handles)
        
    else
        load(fullfile([CF '\' 'A.mat']),'A')
        load(fullfile([CF '\' 'count.mat']),'count')
        
        handles=meas_whale(handles,hObject);
        
        TL=handles.TL;
        
        A{count,2}=dattims{1};
        A{count,3}=dattims{2};
        A{count,9}=theta;
        A{count,10}=H;
        A{count,25}=pathim;
        A{count,4}=Sing_im;
        A{count,11}=TL;
    end
    
    save(fullfile([CF '\' 'A.mat']),'A')
    handles.A=A;
    
    guidata(hObject,handles)
    
    waitfor(handles.checkbox3,'Value'); %waits for 'Correct?' checkbox to be ticked so image properties are set before moving on to next whale or image
    load(fullfile([CF '\' 'A.mat']))
    load(fullfile([CF '\' 'Imquals.mat']))
    drawnow()
    A{count,5}=sharp;
    A{count,7}=water;
    A{count,6}=flukes;
    A{count,8}=sides;
    A{count,27}=unotes;
    
    count=count+1;
    handles.count=count;
    save(fullfile([CF '\' 'A.mat']),'A')
    save(fullfile([CF '\' 'count.mat']),'count')
    set(handles.text9,'String','If more whales to measure in this picture click "Measure another whale". If finished with this image click "Finish"')
    
    uiwait(gcf) %waits for either 'Finish' button or 'measure another whale' button
    
else
    set(handles.text25, 'String', 'Please choose image and enter lidar height')
end
guidata(hObject,handles)



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double
CF=handles.CF;
unotes=get(hObject,'String');
if iscell(unotes)
    unotes=unotes{1};
else
end
save(fullfile([CF '\' 'Imquals.mat']),'unotes','-append')

% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
CF=handles.CF;
startim_num=str2double(get(hObject,'String'));
bestims=handles.bestims;
for ind=1:length(bestims)
    index = find([bestims{ind}] == startim_num);
    if ~isempty(index)
        break
    else
    end
end
handles.subf_ind=ind;
handles.bestim_ind=index;
guidata(hObject,handles)



% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton17.
function pushbutton17_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%MEASURE AT 5%TL button

%Define constants - constants and calculations by Pascal Sirguey
CF=handles.CF;
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

TL=handles.TL;
Lvec=handles.Lvec;
rect=handles.rect;
H=handles.H;
pct5TL=[0.05:0.05:0.95]*TL;
TLvec=Lvec(3,1:end);
xvec=Lvec(1,1:end-1);
yvec=Lvec(2,1:end-1);
pct5ws=zeros(1,19);

set(handles.text9,'String','Click where lines meet edge of whale, use right-click to zoom. Press ENTER to skip a measurement.')

for ind=1:length(pct5TL);
    % xlim([rect(1), rect(1)+rect(3)])
    % ylim([rect(2), rect(2)+rect(4)])
    ind5pct=find(TLvec>pct5TL(ind),1,'first');
    ind5pctv{ind}=ind5pct;
    %calculating perpendicular lines to clicked line segments on whale
    x1=xvec(ind5pct);
    y1=yvec(ind5pct);
    x0=xvec(ind5pct-1);
    y0=yvec(ind5pct-1);
    x2=xvec(ind5pct+1);
    y2=yvec(ind5pct+1);
    
    l=400; %length of one half of guideline
    m=(y2-y0)/(x2-x0); %gradient of length segment that 5% point is found on
    if m==0; %if the line segment is perfectly straight the inverse gradient is infinite!
        
        xg=[x1, x1];
        yg=[y1+l, y1-l];
        
    else
        mp=-1/m; %perpendicular gradient
        
        cp=y1-mp*x1; %intercept value of perp line
        
        %solving for plotting coordinates of ends of guideline
        a=1+mp^2;
        b=2*mp*cp-2*x1-2*y1*mp;
        c=cp^2+x1^2-2*y1*cp+y1^2-l^2;
        
        xg(1)=(-1*b+sqrt(b^2-4*a*c))/(2*a);
        xg(2)=(-1*b-sqrt(b^2-4*a*c))/(2*a);
        yg=mp*xg+cp;
        
    end
    % xv1=linspace(x1,xg(1),500);
    % yv1=mp*xv1+cp; %vector of points along one side of perpendicular line
    % xv2=linspace(x1,xg(2),500);
    % yv2=mp*xv2+cp; %vector of points along other side of perpendicular line
    % C=handles.C;
    hold on
    plot(x1,y1,'Marker','x','Color','b','LineStyle','none','MarkerSize',8,'LineWidth',2)
    
    plot(xg,yg,'LineStyle','-','Color','y')
    xlim([x1-500, x1+500])
    ylim([y1-500, y1+500])
    
    [xw1, yw1, butt]=ginput(1);
    
    if butt==3; %if right click zoom in on point
        
        xlim([xw1-300, xw1+300])
        ylim([yw1-300, yw1+300])
        [xw1,yw1,butt]=ginput(1);
        plot(xw1,yw1,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
        xlim([x1-500, x1+500])
        ylim([y1-500, y1+500])
        
    elseif butt==1
        plot(xw1,yw1,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
        
    else
        continue
    end
  
    [xw2, yw2, butt]=ginput(1);
    if butt==3; %if right click zoom in on point
        
        xlim([xw2-300, xw2+300])
        ylim([yw2-300, yw2+300])
        [xw2,yw2,butt]=ginput(1);
        plot(xw2,yw2,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
        xlim([x1-500, x1+500])
        ylim([y1-500, y1+500])
        
    elseif butt==1
        plot(xw2,yw2,'Marker','x','Color','y','LineStyle','none','MarkerSize',8,'LineWidth',2)
    else
        continue
    end

    P1 = [(xw1-.5)-4608/2; 3456/2-(yw1-.5)]*0.003758; %calculate pixel indices
    P2 = [(xw2-.5)-4608/2; 3456/2-(yw2-.5)]*0.003758; %calculate pixel indices
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
    pct5ws(ind)=Dc; %stores width at each 5% interval
    if H==1;
        pct5ws(ind)=pct5ws(ind)*100/TL;
        set(handles.text8, 'String', strjoin({'Width (%TL):', num2str(pct5ws(ind))})); %print length under image
    else
        set(handles.text8, 'String', strjoin({'Width (m):', num2str(Dc)})); %print length under image
    end
    
    
    
end
xlim([rect(1), rect(1)+rect(3)])
ylim([rect(2), rect(2)+rect(4)])
hold off

% updata data storage cell, A
load(fullfile([CF '\' 'A.mat']))
load(fullfile([CF '\' 'count.mat']))

A(count,28:46)=num2cell(pct5ws);
save(fullfile([CF '\' 'A.mat']),'A')
set(handles.text9,'String','Measure widths, then set image qualities for this image then check "Correct?"')

guidata(hObject,handles)


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if checked will use corrections as calculated by Pascal, otherwise
% assumes no abberation, with a focal length of 24.851372
% Hint: get(hObject,'Value') returns toggle state of checkbox4
I1P=get(hObject,'Value');

handles.I1P=I1P;
set(handles.checkbox4,'Value',I1P)
CF=handles.CF;

save(fullfile([CF '\' 'I1P.mat']),'I1P')
guidata(hObject,handles)



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double
theta=str2double(get(hObject,'String'));
handles.theta=theta;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton18.
function pushbutton18_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Offset = inputdlg({'Offset'},'Give offset between camera image plane and LIDAR in cm...', [1 60]);
CLoffset=str2num(cell2mat(Offset));
set(handles.text32,'String',{'Offset:';CLoffset})
CF=handles.CF;
handles.CLoffset=CLoffset;
save(fullfile([CF '\' 'Offset.mat']),'CLoffset')
guidata(hObject,handles)            % Save the handles structure.
