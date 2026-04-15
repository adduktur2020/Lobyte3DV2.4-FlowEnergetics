function plotFlowApecesXYZIB(glob, newFigure)

    if newFigure
        figure
    end
    
    coordData = glob.apexCoords(2:glob.totalIterations,:);
    
    % --- Flow apices type 1
    xco = coordData(coordData(1:glob.totalIterations-1,1) == 1, 2) .* glob.dx; % / 1000.0; % km
    yco = coordData(coordData(1:glob.totalIterations-1,1) == 1, 3) .* glob.dy;  %/ 1000.0; % km
    zco = coordData(coordData(1:glob.totalIterations-1,1) == 1, 4);
    plot3(xco, yco, zco, '+')            
    
    hold on;
    
    % --- Flow apices type 2
    xco = coordData(coordData(1:glob.totalIterations-1,1) == 2, 2) .* glob.dx; % / 1000.0;
    yco = coordData(coordData(1:glob.totalIterations-1,1) == 2, 3) .* glob.dy; % / 1000.0;
    zco = coordData(coordData(1:glob.totalIterations-1,1) == 2, 4);
    plot3(xco, yco, zco, 'o', 'MarkerFaceColor',[0.424,0.565,0.843])  
    
    % --- Flow routes
    for j = 1:glob.totalIterations
        xco =  glob.transRouteXYZRecord(:, 1, j) .* glob.dx; % / 1000.0; % km
        xco = xco(xco > 0);
        yco = glob.transRouteXYZRecord(:, 2, j) .* glob.dy; % / 1000.0; % km
        yco = yco(yco > 0);
        zco = glob.transRouteXYZRecord(1:numel(xco), 3, j);
        
        line(xco, yco, zco,'Color', [0.424,0.565,0.843]); % cornflower blue
    end
    
    view(0,270);
   
    grid on   
    
    % --- Axis labels
    xlabel("Strike Distance (km)", 'FontSize', 20, 'FontWeight', 'bold');
    ylabel("Dip Distance (km)", 'FontSize', 20, 'FontWeight', 'bold');
    zlabel("Zco (m)", 'FontSize', 20, 'FontWeight', 'bold');
    
    % --- Tick labels styling
    ax = gca;
    ax.FontSize = 20;        % tick label font size
    % ax.FontWeight = 'bold';  % tick label bold
    
    % --- Axis limits
    xlim([150000 350000]);  % km
    ylim([0 500000]);    % km
    
   
    % --- Relabel ticks in km (pseudo tick marks)
    xt = get(ax, 'XTick'); 
    yt = get(ax, 'YTick'); 
    
    ax.XTickLabel = arrayfun(@(x) sprintf('%.0f', x/10000), xt, 'UniformOutput', false);
    ax.YTickLabel = arrayfun(@(y) sprintf('%.0f', y/10000), yt, 'UniformOutput', false);

    % --- Axis limits still in metres, but tick labels appear as km
    xlim([150e3 350e3]);  % still in m internally
    ylim([0 500e3]);      % still in m internally


end
