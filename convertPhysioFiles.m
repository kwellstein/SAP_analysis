function convertPhysioFiles(PID, paths, options)

if nargin==0
    [paths,options] = getDataSpecs([],'main');
    for n = 1:options.dataSet.nParticipants
        for t = 1:options.dataSet.nTasks
            task = options.dataSet.tasks{t};
            if  ~isempty(paths.participant(n).task(t,1).neuroPhysFile)
                physio = readCMRRPhysio(paths.participant(n).task(t,1).neuroPhysFile,1,[paths.participant(n).neuroDir,task,filesep]);
            end
        end
    end
elseif nargin < 2
    [paths,options] = getDataSpecs(PID);
    task = options.dataSet.tasks{t};
    for t = 1:options.dataSet.nTasks
        if  ~strcmp(paths.participant.task(t,1).neuroPhysFile,filesep)
            physio = readCMRRPhysio(paths.participant.task(t,1).neuroPhysFile,1,[paths.participant.neuroDir,task,filesep]);
        end
    end

end

close all

%    base_filename  = 'Physio_DATE_TIME_UUID'
%    DICOM_filename = 'XXX.dcm'
%    show_plot = 1 to graphically display traces after import (optional)
%    output_path = '/path/to/output/' (optional; path to write .log files)
end