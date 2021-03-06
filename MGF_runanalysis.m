homedir = '/Volumes/Vault/Data/Phonetica';
% find subjects
subjects = dir([homedir '/R*']);
srch = '*Phonetica*NR.sqd';
global ft_default
ft_default.checksize = Inf;
trialstrt = ones(length(subjects),1);
trialstrt(2) = 2;
for sub = 2:length(subjects)
    subdir = [homedir '/' subjects(sub).name];
    sqdfiles = dir([subdir '/' srch]);
    
    for sqd = trialstrt(sub):length(sqdfiles)
        sqdfile = [subdir '/' sqdfiles(sqd).name];
        trialdef = struct('trig',164:167,'prestim',0,'poststim',5,'offset',-1);
        trialfun = 'alltrialfun';
        samplefs = 500;
        ncomps = 32;

        [data,trlinfo,layout,neighbours] = Ph_meganalysis(sqdfile,trialdef,trialfun,samplefs);

        seglength = numSubPlot(length(data.trial{1})./data.fsample);
        data = Ph_cleanbadchans(data,layout,neighbours,seglength);

        pcaname=regexp(sqdfile,'R\d{3,4}_(?<name>[a-zA-Z0-9]+)','names');
        pcafile = [subdir '/' pcaname.name '_PCA.jpg'];
        [ft_ica,ft_pca,weights,sphere] = Ph_megica(data,layout,ncomps,pcafile,[]);

        cleanchdata = Ph_cleanica(ft_ica,ft_pca,weights,sphere,layout);

        mkdir([subdir '/Processed']);
        savefile = [subdir '/Processed/' pcaname.name '.mat'];
        save(savefile,'cleanchdata','data','trlinfo','layout','neighbours','ft_ica','ft_pca','weights','sphere','-v7.3');
    end
end
% %% Update trialinfo 
% srch = '*Phonetica*NR.sqd';
% 
% for sub = 1:length(subjects)
%     subdir = [homedir '/' subjects(sub).name];
%     sqdfiles = dir([subdir '/' srch]);
%     
%     for sqd = 1:length(sqdfiles)
%         sqdfile = [subdir '/' sqdfiles(sqd).name];
%         trialdef = struct('trig',164:167,'prestim',0,'poststim',5,'offset',-1);
%         trialfun = 'alltrialfun';
%         samplefs = 500;
%         ncomps = 32;
%         
%         [~,trlinfo] = Ph_meganalysis(sqdfile,trialdef,trialfun,samplefs);
%         
%         pcaname=regexp(sqdfile,'R\d{3,4}_(?<name>[a-zA-Z0-9]+)','names');
%         savefile = [subdir '/Processed/' pcaname.name '.mat'];
%         save(savefile,'trlinfo','-append');
%     end
% end

%%
srch = 'Phonetica*.mat';
for sub = 1:length(subjects)
    subdir = [homedir '/' subjects(sub).name];
    matfiles = dir([subdir '/Processed/' srch]);
    
    for f = 1:length(matfiles)
        matfile = [subdir '/Processed/' matfiles(f).name];
        load(matfile,'cleanchdata','trlinfo','layout','neighbours');
        
        foi = 1:30;
        toi = cleanchdata.time{1}(1:5:end);
        TFR=Ph_tfanalysis(cleanchdata,foi,toi);
        
        TFR = Ph_epochtrial(TFR,trlinfo,'fourierspctrm');
        
        epochfourier = TFR.fourierspctrm;
        TFR = rmfield(TFR,'fourierspctrm');
        
        TFR.powspctrm = abs(epochfourier).^2;
        
        if ~exist([subdir '/TF/'],'dir');
            mkdir([subdir '/TF/']);
        end
        
        namepart = regexp(matfile,'(?<name>[a-zA-z0-9]+)\.mat','names');
        filename = [namepart.name '_pow.mat'];
        savefile = [subdir '/TF/' filename];
        save(savefile,'TFR','-v7.3');
        
        TFR = rmfield(TFR,'powspctrm');
        TFR.phase = angle(epochfourier);
        
        filename = [namepart.name '_phase.mat'];
        savefile = [subdir '/TF/' filename];
        save(savefile,'TFR','-v7.3');
        clear epochfourier TFR
    end
end






