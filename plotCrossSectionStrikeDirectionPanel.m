function plotCrossSectionStrikeDirectionPanel(glob, depos, yCross, lowerLimitX, upperLimitX, maxZ, lobeOrFlowColourCoding, modelName)
% Plot and save a strike-oriented cross section (y = yCross) only.
% Matches the minimalist export style used in plotCrossSectionStrikeDirectionMulT2:
% - Hemipelagic background + transported sediment patches
% - No chronostrat diagram
% - Axes/labels/ticks hidden
% - Fixed figure size; high-DPI export via exportgraphics

    % Setup
    y = yCross;
    plotDx = glob.dx / 1000.0;  % km

    % Determine x-limits
    if lowerLimitX > 0 && upperLimitX > 0
        xStart = lowerLimitX;
        xEnd   = upperLimitX;
    else
        [xStart, xEnd] = findStrikeLimitsTransportedSediment( ...
            depos.transThickness, glob.thicknessThreshold, yCross, glob.xSize, glob.maxIt);
    end

    if xStart < xEnd
        % Figure size (inches), like MulT2
        figWidth  = 20;
        figHeight = 5;

        figHandle = figure('Units','inches','Position',[1, 1, figWidth, figHeight]);
        ax = axes('Parent', figHandle); %#ok<NASGU>
        hold on;

        % --- Hemipelagic background ---
        hpStart = max(xStart - 1, 1);
        hpEnd   = min(xEnd + 1, glob.xSize);
        minStratElevation = min(depos.elevation(y, hpStart:hpEnd, 1));
        minStratElevation = minStratElevation - abs(0.1 * minStratElevation);
        zco1 = ones(1, (hpEnd - hpStart) + 1) * minStratElevation;
        zco2 = depos.elevation(y, hpEnd:-1:hpStart, glob.maxIt);
        zco  = [zco1(:).', zco2(:).'];                     % row vector
        xco_bg = [(hpStart:hpEnd) * plotDx, (hpEnd:-1:hpStart) * plotDx];
        patch(xco_bg, zco, [0.7 0.7 0.7], 'EdgeColor', 'none');

        % --- Transported sediment layers ---
        for t = 2:glob.maxIt
            x = xStart;
            while x < xEnd
                % advance to first cell >= threshold
                while x < xEnd && depos.transThickness(y, x, t) < glob.thicknessThreshold
                    x = x + 1;
                end

                if x < xEnd
                    % Left boundary: erosional vs pinchout
                    if depos.facies(y, x-1, t) == 10
                        xco_patch = x;
                        transUnitBase = depos.elevation(y, x, t-1);
                        transUnitTop  = depos.elevation(y, x, t-1) + depos.transThickness(y, x, t);
                    else
                        xco_patch = x - 1;
                        transUnitBase = depos.elevation(y, x-1, t-1);
                        transUnitTop  = depos.elevation(y, x-1, t-1);
                    end

                    % Collect continuous segment >= threshold
                    while x <= xEnd && depos.transThickness(y, x, t) >= glob.thicknessThreshold
                        xco_patch(end+1)      = x; %#ok<AGROW>
                        transUnitBase(end+1)  = depos.elevation(y, x, t-1); %#ok<AGROW>
                        transUnitTop(end+1)   = depos.elevation(y, x, t-1) + depos.transThickness(y, x, t); %#ok<AGROW>
                        x = x + 1;
                    end

                    % Right boundary: pinchout if not erosional
                    if depos.facies(y, x, t) ~= 10
                        xco_patch(end+1)     = x; %#ok<AGROW>
                        transUnitBase(end+1) = depos.elevation(y, x, t-1); %#ok<AGROW>
                        transUnitTop(end+1)  = depos.elevation(y, x, t-1); %#ok<AGROW>
                    end

                    % Build closed patch
                    xpoly = [xco_patch, xco_patch(end:-1:1)] * plotDx;
                    zpoly = [transUnitBase, transUnitTop(end:-1:1)];

                    % Colour scheme
                    % lobeOrFlowColourCoding == 1 -> colour by lobe
                    % otherwise -> colour by flowColours
                    if lobeOrFlowColourCoding == 1
                        colorDep = depos.flowColoursByLobe(t, :);
                    else
                        colorDep = depos.flowColours(t, :);
                    end

                    patch(xpoly, zpoly, colorDep, 'EdgeColor','none');
                end
            end
        end

        % Optional: enforce vertical range via invisible line (like MulT2)
        if maxZ > 0
            line([xStart, xEnd] * plotDx, [0, maxZ], 'LineStyle','none');
        end

        % --- Minimalist styling (no axes/labels/ticks/title) ---
        ax = gca;
        ax.XColor = 'none';
        ax.YColor = 'none';
        ax.XTick  = [];
        ax.YTick  = [];
        ax.Title.String   = '';
        ax.XLabel.String  = '';
        ax.YLabel.String  = '';
        grid off; box off;

        set(gca, 'LineWidth', 0.5, 'FontSize', 14);
        set(gcf, 'PaperUnits', 'inches', 'PaperPosition', [0 0 figWidth figHeight]);

        % --- Save figure ---
        dpi = 900;
        outName = sprintf('%s_strike_cross_section_y_%.2fkm.png', modelName, yCross * plotDx);
        exportgraphics(figHandle, outName, 'Resolution', dpi);

        close(figHandle); % close if running in batch mode
    else
        fprintf('Cannot plot strike section at y=%d: no deposition found (xStart >= xEnd)\n', yCross);
    end
end

function [xStart, xEnd] = findStrikeLimitsTransportedSediment(transThickness, thicknessThreshold, yPos, xSize, maxIterations)
% Find x-limits of transported-sediment deposition

    xStart = xSize; % Initialize to max
    xEnd   = 0;

    for x = 1:xSize
        for t = 2:maxIterations
            if transThickness(yPos, x, t) > thicknessThreshold && x < xStart
                xStart = x;
            end
            if transThickness(yPos, x, t) > thicknessThreshold && x > xEnd
                xEnd = x;
            end
        end
    end
end
