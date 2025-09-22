function options = getDataInfo(paths,options)

if nargin==0
    % get paths, filenames, participant IDs etc.
    [paths,options] = getDataSpecs([],'main');
end

file = dir([paths.group.DBExport,'*.csv']);
data = readtable([paths.group.DBExport,file(2).name]);
for n = 1:options.dataSet.nParticipants
    for t = 1:options.dataSet.nTasks
        currTask = options.dataSet.tasks{t};

        % get information on whether datasets are complete or not
        expRow = find(data.pid==options.dataSet.PIDs(n));
        if numel(expRow)>1
            for i=1:numel(expRow)
                if isnat(data.date_exp(expRow(i)))
                    delIdx(i) = i;
                end
            end
            expRow(delIdx)=[];
        end
        
        if strcmp(currTask,'SAP')
            options.dataSet.participant(n).task(t).behavComplete  = data.sapbehav(expRow);
            options.dataSet.participant(n).task(t).neuroComplete  = data.sapscan(expRow);
            options.dataSet.participant(n).task(t).physioComplete = data.sapphysio(expRow);
            options.dataSet.participant(n).task(t).emgComplete    = data.sapemg(expRow);
            options.dataSet.participant(n).task(t).eyeComplete    = data.sapeye(expRow);
        elseif strcmp(currTask,'SAPC')
            options.dataSet.participant(n).task(t).behavComplete  = data.sapcbehav(expRow);
            options.dataSet.participant(n).task(t).neuroComplete  = data.sapcscan(expRow);
            options.dataSet.participant(n).task(t).physioComplete = data.sapcphysio(expRow);
            options.dataSet.participant(n).task(t).emgComplete    = data.sapcemg(expRow);
            options.dataSet.participant(n).task(t).eyeComplete    = data.sapceye(expRow);
        elseif strcmp(currTask,'AAA')
            options.dataSet.participant(n).task(t).behavComplete  = data.aaabehav(expRow);
            options.dataSet.participant(n).task(t).neuroComplete  = data.aaascan(expRow);
            options.dataSet.participant(n).task(t).physioComplete = data.aaaphysio(expRow);
            options.dataSet.participant(n).task(t).emgComplete    = data.aaaemg(expRow);
            options.dataSet.participant(n).task(t).eyeComplete    = data.aaaeye(expRow);
        end
    end

end