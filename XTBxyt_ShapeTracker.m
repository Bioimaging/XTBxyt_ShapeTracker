% Performe tracking of a given shape on a given channel
%
%    <CustomTools>
%      <Menu name="Bioimaging XT">
%       <Submenu name="2D+t">
%        <Item name="Shape tracking" icon="Matlab" tooltip="Shape tracking">
%          <Command>MatlabXT::XTBxyt_ShapeTracker(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%    </CustomTools>
%
% Copyright (c) Jan 2018, Bioimaging Core Facility
% v1. Nicolas Liaudet




function [ output_args ] = XTBxyt_ShapeTracker(aImarisApplicationID)
%XTBxyt_ShapeTracker Summary of this function goes here
%   Shape tracking
%    <CustomTools>
%      <Menu>
%        <Item name="Shape tracking" icon="Matlab" tooltip="Shape tracking">
%          <Command>MatlabXT::XTBxyt_ShapeTracker(%i)</Command>
%        </Item>
%      </Menu>
%    </CustomTools>

% connect to Imaris interface
disp('Imaris connection...')
tic
if ~isa(aImarisApplicationID, 'Imaris.IApplicationPrxHelper')
    javaaddpath ImarisLib.jar
    vImarisLib = ImarisLib;
    if ischar(aImarisApplicationID)
        aImarisApplicationID = round(str2double(aImarisApplicationID));
    end
    vImarisApplication = vImarisLib.GetApplication(aImarisApplicationID);
else
    vImarisApplication = aImarisApplicationID;
end
vDataSet = vImarisApplication.GetDataSet;
% vDataSetClone = vImarisApplication.GetDataSet.Clone;


toc




vDataSizeYXZTC = [vDataSet.GetSizeY, vDataSet.GetSizeX,...
                  vDataSet.GetSizeZ, vDataSet.GetSizeT,...
                  vDataSet.GetSizeC];

% check the date dimension
if vDataSizeYXZTC(3)>1
    errordlg('Z-stack not supported','Wrong data type');
    return
% elseif vDataSizeYXZTC(4)>1
%     errordlg('Time series not supported','Wrong data type');   
%     return
end

% get the channel names
ChName = cell(vDataSizeYXZTC(5),1);
for idxC = 1:vDataSizeYXZTC(5)
    ChName{idxC} = char(vDataSet.GetChannelName(idxC-1));
end

% get the data
disp('Get Data...')
tic
switch char(vDataSet.GetType)
    case 'eTypeUInt8'
        BitDepth = 'uint8';
    case 'eTypeUInt16'
        BitDepth = 'uint16';
    case 'eTypeFloat'
        BitDepth = 'single';
end


toc


uiselect(ChName,BitDepth,vDataSizeYXZTC,vDataSet,vImarisApplication)
end
 
function uiselect(ChName,BitDepth,vDataSizeYXZTC,vDataSet,vImarisApplication)
%GUI for user interaction


prompt = {'X-half-fraction of the image :','Y-half-fraction of the image :'};
dlg_title = 'Spatial window';
num_lines = 1;
defaultans = {'0.1','0.1'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
xy_frac_range = str2double(answer');



h.f = figure('units','pixels','position',[50 50 340 150],...
    'toolbar','none','menu','none','Name','Shape Tracking',...
    'Resize','off','NumberTitle','off','Visible','off');
%,'CloseRequestFcn','');



uicontrol('Parent',h.f,'Style','text','Units','pixel',...
    'Position',[10 130 119 13],'String','Reference:',...
    'HorizontalAlignment','Center');

h.tRef = uicontrol('Parent',h.f,'Style','listbox','String',ChName,...
    'Value',length(ChName),'Min',2,'Max',1,...
    'Units','Pixel','Position', [10 20 119 110]);


uicontrol('Parent',h.f,'Style','text','Units','pixel',...
    'Position',[140 130 119 13],'String','Track on:',...
    'HorizontalAlignment','Center');

h.tTra = uicontrol('Parent',h.f,'Style','listbox','String',ChName,...
    'Value',2,'Min',2,'Max',1,...
    'Units','Pixel','Position', [140 20 119 110]);



h.but(1) = uicontrol('Parent',h.f,'Style','PushButton','String','OK',...
    'Units','pixel','Position',[284 45 50 25],'FontWeight','Bold',...
    'Callback',@OK);

h.but(2) = uicontrol('Parent',h.f,'Style','PushButton','String','CANCEL',...
    'Units','pixel','Position',[284 20 50 25],'FontWeight','Bold',...
    'Callback',@CANCEL);

align(h.but,'VerticalAlignment','Distribute')

movegui(h.f,'center')



vDataSet = vImarisApplication.GetDataSet;

set(h.f,'Visible','on')
    

    function OK(hObject,eventdata)
        %do the job...
        
        vDataSetClone = vDataSet.Clone;
        
        TraStackYXT   = zeros(vDataSizeYXZTC([1 2 4]),BitDepth);
%         RefTemplateYX = zeros(vDataSizeYXZTC([1 2]),BitDepth);
        
        
        
        switch BitDepth
            case 'uint8'
                for idxT = 1:vDataSizeYXZTC(4)
                    imtra = typecast(vDataSetClone.GetDataVolumeAs1DArrayBytes(h.tTra.Value-1,idxT-1),BitDepth);                                                                                
                    imtra = reshape(imtra,vDataSizeYXZTC([1 2]));
                    TraStackYXT(:,:,idxT) = imtra;                    
                    
                    imref = typecast(vDataSetClone.GetDataVolumeAs1DArrayBytes(h.tRef.Value-1,idxT-1),BitDepth);                    
                    imref = reshape(imref,vDataSizeYXZTC([1 2]));
                    imref = imref ~= 0; 
                    if any(imref(:))
                        RefTemplateYX = imref;
                    end
                
                end                
                                
            case 'uint16'
                for idxT = 1:vDataSizeYXZTC(4)
                    im = typecast(vDataSetClone.GetDataVolumeAs1DArrayShorts(h.tTra.Value-1,idxT-1),BitDepth);
                    im = reshape(im,vDataSizeYXZTC([1 2]));
                    TraStackYXT(:,:,idxT) = im;
                    
                    imref = typecast(vDataSetClone.GetDataVolumeAs1DArrayShorts(h.tRef.Value-1,idxT-1),BitDepth);                    
                    imref = reshape(imref,vDataSizeYXZTC([1 2]));
                    imref = imref ~= 0; 
                    if any(imref(:))
                        RefTemplateYX = imref;
                    end
                end
                
            case 'single'
                for idxT = 1:vDataSizeYXZTC(4)
                    im = typecast(vDataSetClone.GetDataVolumeAs1DArrayFloats(h.tTra.Value-1,idxT-1),BitDepth);
                    im = reshape(im,vDataSizeYXZTC([1 2]));
                    TraStackYXT(:,:,idxT) = im;
                    
                    imref = typecast(vDataSetClone.GetDataVolumeAs1DArrayFloats(h.tRef.Value-1,idxT-1),BitDepth);                    
                    imref = reshape(imref,vDataSizeYXZTC([1 2]));
                    imref = imref ~= 0; 
                    if any(imref(:))
                        RefTemplateYX = imref;
                    end
                end
        end
        RefTemplateYX = cast(RefTemplateYX,BitDepth);
        
        vDataSetClone.SetSizeC(vDataSizeYXZTC(5)+1)
        idxC = vDataSetClone.GetSizeC;
        
        
        for idxT = 1:vDataSizeYXZTC(4)
            cc = normxcorr2(RefTemplateYX,TraStackYXT(:,:,idxT));

            dx = round(vDataSizeYXZTC(1)*(1-xy_frac_range(1))):round(vDataSizeYXZTC(1)*(1+xy_frac_range(1)));
            dy = round(vDataSizeYXZTC(2)*(1-xy_frac_range(2))):round(vDataSizeYXZTC(2)*(1+xy_frac_range(2)));                        
            cc = cc(dx,dy);
            [ypeak, xpeak] = find(cc==max(cc(:)));

            yoffSet = ypeak-vDataSizeYXZTC(1)+dy(1)-1;
            xoffSet = xpeak-vDataSizeYXZTC(2)+dx(1)-1;
            
            
            [StackDone, ~] = imtranslate(RefTemplateYX,[xoffSet yoffSet],'OutputView','same');
            switch BitDepth
                case 'uint8'
                    vDataSetClone.SetDataVolumeAs1DArrayBytes(StackDone(:),idxC-1,idxT-1);
                case 'uint16'
                    vDataSetClone.SetDataVolumeAs1DArrayShorts(StackDone(:),idxC-1,idxT-1);
                case 'single'
                    vDataSetClone.SetDataVolumeAs1DArrayFloats(StackDone(:),idxC-1,idxT-1);
            end
        end
        
        disp(['Done, you can close the window'])
        vImarisApplication.SetDataSet(vDataSetClone)
    end


   


    function CANCEL(hObject,eventdata)
         close(h.f)
    end

end


