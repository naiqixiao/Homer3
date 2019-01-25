function calcProcStreamChanged(newval)

if ~exist('newval','var') || isempty(newval)
    newval = 1.6;
end

dataTree = LoadDataTree('.nirs');
dataTree.group.subjs(2).runs(2).procStream.EditParam(3, 2, newval);
dataTree.group.Calc();
dataTree.group.Save();
