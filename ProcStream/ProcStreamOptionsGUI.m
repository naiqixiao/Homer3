function varargout = ProcStreamOptionsGUI(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ProcStreamOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ProcStreamOptionsGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~strcmp(varargin{end},'userargs')
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end




% ----------------------------------------------------------
function ProcStreamOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ProcStreamOptionsGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(hObject,'visible','off');  % to be turnedmade visible in ProcStreamOptionsGUI_OutputFcn

currElem = varargin{1};
currElem.handles.ProcStreamOptionsGUI = hObject;
procInput = currElem.procElem.procInput;
procFunc = procInput.procFunc;

if isempty(procFunc)
    return;
end

clf(hObject);
nfunc = length(procFunc);

% If no functions, throw up empty gui
if nfunc==0
    uicontrol(hObject, 'style','text', 'string','');
	% Need to make sure position data is saved in pixel units at end of function 
	% to as these are the units used to reposition GUI later if needed
    set(hObject, 'units','characters');
    setappdata(hObject,'position',get(hObject, 'position'));
    return;
end

% Pre-calculate figure height
for iFunc = 1:nfunc
    funcHeight(iFunc) = 1+procFunc(iFunc).nFuncParam-1;
end
ystep = 1.8;
ysize = 1.5;
ysize_tot = sum(funcHeight)*ystep + nfunc*2 + 5;
xsize_fname = getFuncNameMaxStrLength(procFunc);
xsize_pname = getParamNameMaxStrLength(procFunc);
xpos_pname = xsize_fname+10;
xpos_pedit = xpos_pname+xsize_pname+10;
xpos_pbttn = xpos_pedit+15;
xsize_tot  = xpos_pbttn+15;

% Set figure size 
if length(varargin)>2 && ~isempty( varargin{2})
    pos = varargin{2};  % previous figures position
else
    pos = get(hObject, 'position');
end
set(hObject, 'color',[1 1 1]);
set(hObject, 'position',[pos(1),pos(2),xsize_tot,ysize_tot]);

% Display functions and parameters in figure
ypos = ysize_tot-5;
for iFunc = 1:nfunc
    
    % Draw function name
    xsize = length(procFunc(iFunc).funcName);
    xsize = xsize+(5-mod(xsize,5));
    h_fname = uicontrol(hObject, 'style','text', 'units','characters', 'position',[2 ypos xsize ysize],...
                        'string',procFunc(iFunc).funcName);
    set(h_fname,'backgroundcolor',[1 1 1], 'units','normalized');
    set(h_fname, 'horizontalalignment','left');
    set(h_fname, 'tooltipstring',procFunc(iFunc).funcHelp.genDescr);
    
    % Draw pushbutton to see output results if requested in config file
    if procFunc(iFunc).funcArgOut(1)=='#'
        h_bttn = uicontrol(hObject, 'style','pushbutton', 'units','characters', 'position',[xpos_pbttn ypos 10 ysize],...
                          'string','Results');
        eval( sprintf(' fcn = @(hObject,eventdata)ProcStreamOptionsGUI(''pushbuttonProc_Callback'',hObject,%d,guidata(hObject));',iFunc) );
        set( h_bttn, 'Callback',fcn, 'units','normalized')
    end
    
    % Draw list of parameters
    for iParam = 1:procFunc(iFunc).nFuncParam
        % Draw parameter names
        xsize = length(procFunc(iFunc).funcParam);
        xsize = xsize+(5-mod(xsize,5))+5;
        h_pname=uicontrol(hObject, 'style','text', 'units','characters', 'position',[xpos_pname, ypos, xsize_pname, ysize],...
                          'string',procFunc(iFunc).funcParam{iParam});
        set(h_pname,'backgroundcolor',[1 1 1], 'units','normalized');
        set(h_pname, 'horizontalalignment', 'left');
        set(h_pname, 'tooltipstring', procFunc(iFunc).funcHelp.paramDescr{iParam});

        % Draw parameter edit boxes
        h_pedit=uicontrol(hObject,'style','edit','units','characters','position',[xpos_pedit ypos 10 1.5]);
        procFunc(iFunc).funcParamHandle{iParam} = h_pedit;
        set(h_pedit,'string',sprintf(procFunc(iFunc).funcParamFormat{iParam}, ...
            procFunc(iFunc).funcParamVal{iParam} ) );
        set(h_pedit,'backgroundcolor',[1 1 1]);
        eval( sprintf(' fcn = @(hObject,eventdata)ProcStreamOptionsGUI(''edit_Callback'',hObject,[%d %d],guidata(hObject));',iFunc,iParam) );
        set( h_pedit, 'Callback',fcn, 'units','normalized');

        ypos = ypos - ystep;
    end
    
    % If function has no parameters, skip a step in the y direction
    if procFunc(iFunc).nFuncParam==0
        ypos = ypos - ystep;
    end
    
    
    % Draw divider between functions and function parameter lists
    if iFunc<nfunc
        h_linebttn = uicontrol(hObject,'style','pushbutton','units','characters','position',[0 ypos xsize_tot .3],...
                               'enable','off');
        set(h_linebttn, 'units','normalized');
        ypos = ypos - ystep;
    end
    
end

procParam0 = [];
for iFunc=1:length(procFunc)
    for iParam=1:procFunc(iFunc).nFuncParam
        eval( sprintf('procParam0.%s_%s = procInput.procFunc(iFunc).funcParamVal{iParam};',...
                      procFunc(iFunc).funcName, procFunc(iFunc).funcParam{iParam}) );
    end
end
procInput.procFunc = procFunc;
procInput.procParam = procParam0;
currElem.procInput = procInput;
hmr.currElem = currElem;

% Make sure the options GUI fits on screen
[b, p] = guiOutsideScreenborders(hObject);
if abs(b(4))>0 || abs(b(2))>0
    h = ysize_tot/100;
    k = 1-h;
    positionGUI(hObject, p(1), 0.12, p(3), k*h+h);
end

% Why do we save this? Matlab doesn't take into account multiple monitors 
% when deciding whether a figure is going beyond it seems that whatever position is assigned to
% the gui, if it's outside the primary monotor (ie, on a secondary monitor)
% the gui_*** functions reposition it right back to the primary monitor, 
% overriding the position settings in this function. Annoying! 
% To overcome this problem we save the position data here and then 
% reposition if back to this setting in the ProcStreamOptionsGUI_OutputFcn
% which is called function after matlab's meddling. 

setappdata(hObject,'position',get(hObject, 'position'));



% ----------------------------------------------------------
function varargout = ProcStreamOptionsGUI_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = hObject;

% Restore the gui position set in ProcStreamOptionsGUI_OpeningFcn
p = getappdata(hObject,'position');
set(hObject, 'position',[p(1), p(2), p(3), p(4)]);
set(hObject,'visible','on');



% ----------------------------------------------------------
function edit_Callback(hObject, eventdata, handles) 
global hmr

dataTree = hmr.dataTree;

iFunc  = eventdata(1);
iParam = eventdata(2);
val = str2num( get(hObject,'string') ); % need to check if it is a valid string

str = dataTree.currElem.procElem.EditProcParam(iFunc, iParam, val);
set( hObject, 'string', str);

% Check if we should apply the param edit to all nodes of the current nodes
% level
if ~hmr.guiMain.applyEditCurrNodeOnly
    if dataTree.currElem.procType==2
        for ii=1:length(dataTree.group.subjs)
            dataTree.group.subjs(ii).EditProcParam(iFunc, iParam, val);
        end
    elseif dataTree.currElem.procType==3
        for ii=1:length(dataTree.group.subjs)
            for jj=1:length(dataTree.group.subjs(ii).runs)
                dataTree.group.subjs(ii).runs(jj).EditProcParam(iFunc, iParam, val);
            end
        end
    end
end


% ----------------------------------------------------------
function pushbutton_Callback(hObject, eventdata, handles) 
global hmr

dataTree = hmr.dataTree;
procInput = dataTree.currElem.procInput;

% parse output parameters
foos = procInput.procFunc(eventdata).funcArgOut;

% remove '[', ']', and ','
for ii=1:length(foos)
    if foos(ii)=='[' | foos(ii)==']' | foos(ii)==',' | foos(ii)=='#'
        foos(ii) = ' ';
    end
end

% get parameters for Output to procResult
sargin = '';
lst = strfind(foos,' ');
lst = [0 lst length(foos)+1];
flag = 1;
for ii=1:length(lst)-1
    foo2 = foos(lst(ii)+1:lst(ii+1)-1);
    idx = strfind(foo2,'foo');
    if (isempty(idx) || idx>1) && ~isempty(foo2)
        sargin = sprintf( '%s, hmr.procResult.%s',sargin,foo2);
    elseif idx==1
        sargin = sprintf( '%s, []',sargin);
    end
end

eval( sprintf( '%s_result( %s );', procInput.procFunc(eventdata).funcName, sargin(2:end) ) );

hmr.dataTree.currElem.procInput = procInput;




% -----------------------------------------------------------------
function maxnamelen = getFuncNameMaxStrLength(procFunc)

maxnamelen=0;
for iFunc =1:length(procFunc)
    if length(procFunc(iFunc).funcName) > maxnamelen
        maxnamelen = length(procFunc(iFunc).funcName)+1;
    end
end




% -----------------------------------------------------------------
function maxnamelen = getParamNameMaxStrLength(procFunc)

maxnamelen=0;
for iFunc=1:length(procFunc)
    for iParam=1:length(procFunc(iFunc).funcParam)
        if length(procFunc(iFunc).funcParam{iParam})>maxnamelen
            maxnamelen = length(procFunc(iFunc).funcParam{iParam})+1;
        end
    end
end




% --------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

hGui=get(get(hObject,'parent'),'parent');
close(hGui);



% -------------------------------------------------------------------
function [b, p] = guiOutsideScreenborders(hObject)

b = [0, 0, 0, 0];
units_orig = get(hObject,'units');
set(hObject,'units','normalized');
p = get(hObject,'position');
if p(1)+p(3)>=1 || p(1)<0
    if p(1)+p(3)>=1
        b(1)=(p(1)+p(3))-1;
    else
        b(1)=0-p(1);
    end
end
if p(2)+p(4)>=1 || p(2)<0
    if p(2)+p(4)>=1
        b(2)=(p(2)+p(4))-1;
    else
        b(2)=0-p(2);
    end
end
if p(3)>=1
    b(3)=p(3)-1;
end
if p(4)>=1
    b(4)=p(4)-1;
end
set(hObject,'units',units_orig);



