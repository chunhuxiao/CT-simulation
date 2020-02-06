function [dataflow, prmflow, status] = reconnode_databackup(dataflow, prmflow, status)
% recon node, backup data
% [dataflow, prmflow, status] = reconnode_databackup(dataflow, prmflow, status);

% parameters set in pipe
backupprm = prmflow.pipe.(status.nodename);

if isfield(backupprm, 'index') && ~isempty(backupprm.index)
    bkindex = '';
else
    bkindex = num2str(backupprm.index);
end

% dataflow, prmflow and status
if isfield(backupprm, 'dataflow')
    dataflow = backupdata(dataflow, backupprm.dataflow, bkindex);
end
if isfield(backupprm, 'prmflow')
    prmflow = backupdata(prmflow, backupprm.prmflow, bkindex);
end
if isfield(backupprm, 'status')
    status = backupdata(status, backupprm.status, bkindex);
end

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end


function data = backupdata(data, bkfields, index)
% copy data.bkfields to data.bkfields_bk

% ext
name_ext = ['_bk' index];
% back up
if iscell(bkfields)
    for ii = 1:length(bkfields)
        if isfield(data, bkfields{ii})
            data.([bkfields{ii} name_ext]) = data.(bkfields{ii});
        end
    end
else
    if isfield(data, bkfields)
        data.([bkfields name_ext]) = data.(bkfields);
    end
end
    
end