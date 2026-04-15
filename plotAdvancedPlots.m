function plotAdvancedPlots(glob, depos)

        % Define two cross-section positions, to calculate stats through the model
        xCross = 250; % Position of the dip-oriented section on the x-axis
        yCross = 280;  % Position of the strike-oriented section on the y-axis
        glob.sedimentSupplyFreq = 1.0 / glob.flowSedVolOscillationPeriod; % Define this here because not defined in glob in currently saved versions of the two model runs loaded in the lines above
        glob.thicknessThreshold = 0.001; % Thickness threshold used for various post-run analysis e.g. strat completeness, runs analysis
        glob.modelName = "BigFan";
        
        % Set the flow colour for each iteration. Note that lobe colours are set in function calculateFanLobesFromFlowApices
        depos.flowColours = zeros(glob.totalIterations,3);
        depos.flowColours(1:glob.totalIterations,:) = [ones(glob.totalIterations,1), rand(glob.totalIterations,1), zeros(glob.totalIterations,1)];
        
        % plotFlowCentroidTimeseries(glob, depos);
%         plotFlowApecesTimeseries(glob, depos);
        plotLobeVolumeTimeseries(glob, depos);
        
        fprintf("Plot flow apices positions, xy iteration ...")
        plot3DView(glob, depos, 1, 1, 0.75)
        plotFlowApecesXYZ(glob, 0)
        fprintf("Done\n")
        
%         plotSingleFlowMapsAnimated(glob, depos, 2, 200, 1);
        
%         plotTraverseAnimation(glob, depos);

        fprintf('Plot cross sections...');
        plotCrossSectionStrikeDirection(glob, depos, yCross, 0,0,0, 1, glob.modelName);
        % plotCrossSectionStrikeDirection(glob, depos, yCross, 220,302,0, 1, glob.modelName);
        % plotCrossSectionStrikeDirectionPanel(glob, depos, yCross, 220,302,0, 1, glob.modelName);
%         plotCrossSectionDipDirection(glob, depos, xCross, 0,0,0, 1, glob.modelName);
        fprintf('Done\n');

%         fprintf('Plot vertical sections...');
%         plotVerticalSection(glob, depos, 250, yCross, glob.modelName);
%         plotVerticalSection(glob, depos, 230, yCross, glob.modelName);
%         fprintf('Done\n');

%         fprintf('Plot vertical section and correlative chronostrat');
%         plotVerticalSectionAndChronostratsTriangles(glob, depos, xCross, yCross, glob.modelName);
%         fprintf('Done\n');

%         
%         fprintf("Plot 3D view of flow history ...")
%         plotSingleFlowMaps(glob, depos, 2, glob.it-1);
%         fprintf("Done\n")

%           fprintf('Plot flow centroids...');
%           plotCentroids(glob, depos, glob.modelName);
%           fprintf('Done\n');

%           
%           fprintf('Plot chronostrat diagrams slices through model animation...');
%           plotChronostratTraverseAnimation(glob, depos);
%           fprintf('Done\n');

%           fprintf('Plot maps, P value, strat completeness and maximum power spectra frequencies etc...');
%           plotStatsMaps(glob, depos, glob.modelName);
%           fprintf('Done\n');
          
%           fprintf('Plot significant spectral peaks count bar chart...');     
%           plotSpectralPeakCounts(glob.significantPeakCount, glob.sedimentSupplyPeriod, glob.modelName); % Note updated on 25.7 to send just sigPeakCount rather than all of glob structure, and then sediment supply period added too
%           fprintf('Done\n');
% 
%           fprintf('Plot bed thickness distribution etc...');
%           plotBedThicknessDistribution(glob, depos);
%           fprintf('Done\n');

%           fprintf('Calculate and plot power spectra at X=97, Y=50 ...');
%           [~] = oneSectionPowerSpectrumAnalysis(glob, depos.transThickness, xCross, yCross, 500, 1, 50, 500, 1);
%           [~] = oneSectionPowerSpectrumAnalysis(glob, depos.transThickness, xCross, 150, 500, 1, 50, 500, 1);
%           [~] = oneSectionPowerSpectrumAnalysis(glob, depos.transThickness, 190, 125, 500, 1, 50, 500, 1);
%           [~] = oneSectionPowerSpectrumAnalysis(glob, depos.transThickness, 190, 150, 500, 1, 50, 500, 1);
          
%    
% 
%         plotPvsCompleteness(glob, depos);
%         
%         fprintf('Analysing flow overlap time series...');
%         analyseFlowOverlapTimeseries(glob);
%         fprintf('Done\n');

end