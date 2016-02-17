function ft_ICA = Ph_megica(data,layout,ncomps)

        data.trial{1} = data.trial{1} - repmat(mean(data.trial{1},2),1,size(data.trial{1},2));
        [EigenVectors]=pcsquash(data.trial{1});
        
        ft_PCA = ft_componentanalysis(struct('demean','no','unmixing',EigenVectors','topolabel',{data.label}),data);

         cfg = [];
        cfg.layout = layout; % specify the layout file that should be used for plotting
        cfg.viewmode = 'component';
        cfg.continous = 'yes';
        cfg.compscale = 'local';
        cfg.blocksize = 20;
        cfg.ylim = [-4 4].*std(ft_PCA.trial{1}(:));
        
        ft_databrowser(cfg, ft_PCA);
        saveas(gcf,['PCA_twotones' num2str(i)],'jpg')
        close(gcf)
        
        % Automatically remove 1st PCA component and get ICA 
        
        cfg = [];
        cfg.demean = 'no';
        cfg.component = 1;
        PCA_postreject = ft_rejectcomponent(cfg,ft_PCA);
        clear ft_PCA
        PCA_postreject.trial{1} = PCA_postreject.trial{1} - repmat(mean(PCA_postreject.trial{1},2),1,size(PCA_postreject.trial{1},2));
        [EigenVectors]=pcsquash(PCA_postreject.trial{1});            % pca eigenvectors from eeglab
        ft_PCAreject1 = ft_componentanalysis(struct('demean','no','unmixing',EigenVectors','topolabel',{PCA_postreject.label}),PCA_postreject);
%       
        [weights, sphere]=runica(ft_PCAreject1.trial{1}(1:ncomps,:),'lrate',0.001);

        dummy = ft_PCAreject1; dummy.trial{1} = ft_PCAreject1.trial{1}(1:ncomps,:); dummy.topo = dummy.topo(1:ncomps,1:ncomps);
        dummy.label = dummy.label(1:ncomps); dummy.topolabel = dummy.topolabel;

        ft_ICA = ft_componentanalysis(struct('demean','no','unmixing',weights*sphere,'topolabel',{dummy.label}),dummy);

        % change topography data to match ica + pca transformation
        ft_ICA.topolabel_orig = ft_ICA.topolabel;
        ft_ICA.topolabel = ft_PCAreject1.topolabel;
        ft_ICA.topo = pinv(weights*sphere*EigenVectors(:,1:ncomps)'*eye(length(EigenVectors)));
end