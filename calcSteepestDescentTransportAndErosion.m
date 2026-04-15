function [depos, erosionMap, deposMap, glob, flow, nextFlowXco, nextFlowYco, transRouteXYZ] = calcSteepestDescentTransportAndErosion(glob, depos, flow, topog) 
% Calculate sediment channel-type transport route from the point of flow input flowXco,flowYco using steepest gradient descent method.
% If all deeper destination cells are equal elevation, use a random number to select one - see details in findDeepestNewCell

    velocityHistory = []; 

    % set initial conditions
    iterations = 0;
    iterationLimit = 1000;
    apexType = 0;
    prevFlowXco = flow.xco;
    prevFlowYco = flow.yco;
    transRouteXYZ = zeros(glob.ySize,3);
    transLength = 1;
    deposMap = zeros(glob.ySize, glob.xSize);
    erosionMap = zeros(glob.ySize, glob.xSize);
    obstDeposVol = 0; % keep a record of how much volume of each flow deposited behind obstacles, to distinguish from norm dispersive distribution
    obstDeposCount = 0; % Keep a record of how many grid points receive depositon behind an obstacle

    % NEW: ensure tracker cell exists and is empty for this iteration
    if ~isfield(glob,'track_route') || numel(glob.track_route) < glob.it || isempty(glob.track_route{glob.it})
        glob.track_route{glob.it} = [];
    end
    
    % Call subfunction below to initialize various grid and gradient calculation matrices. 
    % Don't need all params returned at this point, just gradient and velocities
    [neighboursXYIncs, neighboursXYDists] = initialiseGridAndGradientMatrices(glob.dx, glob.dy);
    [~,~, gradient, ~,~,~] = findSteepestGradient(topog, prevFlowYco, prevFlowXco, neighboursXYIncs, neighboursXYDists);
    [flow.velocity, flow.shearVelocity] = calcInitialFlowVelocity(glob, gradient);

    % Log inlet Froude using step C
    rho_bulk0 = flow.sedConcentration * glob.rhoSolid + (1 - flow.sedConcentration) * glob.rhoAmbient;
    R0 = (rho_bulk0 - glob.rhoAmbient) / glob.rhoAmbient;
    FrD0 = flow.velocity / sqrt((glob.gravity * R0) * glob.totalFlowThickness);
    glob.FrD_inlet(glob.it) = FrD0;

    if ~isfield(glob,'FrD_route') || numel(glob.FrD_route) < glob.it || isempty(glob.FrD_route{glob.it})
        glob.FrD_route{glob.it} = [];
    end
    if ~isfield(glob,'sedConc_route') || numel(glob.sedConc_route) < glob.it || isempty(glob.sedConc_route{glob.it})
        glob.sedConc_route{glob.it} = [];
    end
    if ~isfield(glob,'sedVol_route') || numel(glob.sedVol_route) < glob.it || isempty(glob.sedVol_route{glob.it})
        glob.sedVol_route{glob.it} = [];
    end

    if ~isfield(glob,'u_route') || numel(glob.u_route) < glob.it || isempty(glob.u_route{glob.it})
        glob.u_route{glob.it} = [];          % flow velocity U (m/s)
    end
    if ~isfield(glob,'erodeThick_route') || numel(glob.erodeThick_route) < glob.it || isempty(glob.erodeThick_route{glob.it})
        glob.erodeThick_route{glob.it} = [];          % eroded thickness
    end
    
    if ~isfield(glob,'flowTime_route') || numel(glob.flowTime_route) < glob.it || isempty(glob.flowTime_route{glob.it})
        glob.flowTime_route{glob.it} = [];          % eroded thickness
    end

    if ~isfield(glob,'flowRate_route') || numel(glob.flowRate_route) < glob.it || isempty(glob.flowRate_route{glob.it})
        glob.flowRate_route{glob.it} = [];          % eroded thickness
    end

    if ~isfield(glob,'topopErode_route') || numel(glob.topogErode_route) < glob.it || isempty(glob.topogErode_route{glob.it})
        glob.topogErode_route{glob.it} = [];          % eroded thickness
    end

    % Flow until one of the end flow conditions reached,
    % Because flow can get trapped oscillating between x+1 x-1 cells, include an iteration limit in case this happens
    while flow.stopped == false && iterations < iterationLimit
    
        % Find deepest cell coords that are next xco and yco for the flow, checking for ponding (sedTrap) or edge of grid (sedLost)          
        [nextFlowYco, nextFlowXco, gradient, flow.lostOffGrid, flow.behindObstacle, obstacleRelief, randomRouting] = findSteepestGradient(topog, prevFlowYco, prevFlowXco, neighboursXYIncs, neighboursXYDists);
        % [flow.velocity, flow.shearVelocity] = calcSteepestDescentFlowVelocityIBN(glob, gradient, flow.velocity, flow.shearVelocity);

        % log velocity
        %velocityHistory(end+1) = flow.velocity;

        
        % % — record this step’s Froude number on the route — added newly
        % %FrD_step = flow.velocity / sqrt(glob.reducedGravity * glob.totalFlowThickness);
        % % Ensure FrD_route field is initialized
        % if ~isfield(glob, 'FrD_route') || length(glob.FrD_route) < glob.it || isempty(glob.FrD_route{glob.it})
        %     glob.FrD_route{glob.it} = [];
        % end
        % 
        % glob.FrD_route{glob.it}(end+1) = FrD_step;
        % --- Velocity update WITH step C ---

        [flow.velocity, flow.shearVelocity] = calcSteepestDescentFlowVelocityIBN(glob, gradient, flow.velocity, flow.shearVelocity, flow.sedConcentration);

        % --- Step Froude using the SAME step C ---
        rho_bulk = flow.sedConcentration * glob.rhoSolid + (1 - flow.sedConcentration) * glob.rhoAmbient;
        R = (rho_bulk - glob.rhoAmbient) / glob.rhoAmbient;
        FrD_step = flow.velocity / sqrt((glob.gravity * R) * glob.totalFlowThickness);
        glob.FrD_route{glob.it}(end+1)     = FrD_step;
        glob.sedConc_route{glob.it}(end+1) = flow.sedConcentration;
        glob.sedVol_route{glob.it}(end+1) = flow.sedVolume;
        glob.u_route{glob.it}(end+1)     = flow.velocity;

        % NEW: default event code = 0 (no C/Vol change this step)
        eventCode = 0;
        
        if flow.lostOffGrid == true % next flow xy coords are at the grid edge, so flow exited the model grid before deposition

            flow.stopped = true;
            fprintf(" left grid at %d %d no deposition\n", nextFlowXco, nextFlowYco);
            apexType = 3;

        elseif flow.behindObstacle == true && flow.velocity <= 0 % Flow is still on the grid, but trapped in a topographic low and moving too slowly to get over

            if obstacleRelief < glob.totalFlowThickness % Height of topographic obstacle less than flow height, so strip base of flow, deposit and continue
                
                % Model flow stripping - part of flow volume left behind the obstacle
                % Calculate thickness of sediment to deposit behind the obstacle, record in deposMap and record volume in obstDeposVol
                [flow, deposMap, obstDeposVol] = calcFlowObstacleInteract(glob, flow, deposMap, prevFlowYco, prevFlowXco, obstacleRelief, obstDeposVol);
                obstDeposCount = obstDeposCount + 1;

           
                % NEW: mark event as '2' (behind obstacle changed C/Vol)
                eventCode = 2;

                % erodeThick = deposMap;
                
                % Calculate onward flow route over obstacle into the lowest elevation y+1 grid cell found with findSteepestGradient
                % using a reduced set of neighbour grid coords in neighbursXYIncs
                [~, prevFlowXco, ~,~,~,~, randomRouting] = findSteepestGradient(topog, prevFlowYco, prevFlowXco, neighboursXYIncs(2:4,:), neighboursXYDists(2:4));
                prevFlowYco = prevFlowYco + 1;
                transRouteXYZ(transLength,:) = [prevFlowXco, prevFlowYco, topog(prevFlowYco, prevFlowXco)];
                transLength = transLength + 1;

            else % Height of topographic obstacle equal to or greater than flow height
                flow.stopped = 1;
                obstDeposCount = obstDeposCount + 1;
                apexType = 1;
                fprintf("WARNING - flow completely block-stopped by %3.2f m obstacle > %3.2m", obstacleRelief, glob.totalFlowThickness);
            end 

        else
            % Flow is on the grid, not in a topographic low, so calculate velocity to see if it continues or stops

            if flow.velocity > glob.deposVelocity % is the velocity still greater than the threshold velocity for deposition?

                flow.stopped = false;   % If so, continue the flow by moving it into the deepest adjacent cells
                
                % [depos, topog, erosionMap, flow.sedVolume, flow.sedConcentration] = calcFlowErosion(glob, depos, flow, topog, erosionMap, prevFlowXco, prevFlowYco);
                [depos, topog, erosionMap, flow.sedVolume, flow.sedConcentration, erodeThick, flowTime, flowRate, topogErode] = calcFlowErosionIBL(glob, depos, flow, topog, erosionMap, prevFlowXco, prevFlowYco);
                

                % NEW: if erosion depth at this cell > 0, mark event '1'
                if erosionMap(prevFlowYco, prevFlowXco) > 0
                    eventCode = 1;
                end
                
                prevFlowYco = nextFlowYco; 
                prevFlowXco = nextFlowXco;
                transRouteXYZ(transLength,:) = [nextFlowXco, nextFlowYco, topog(nextFlowYco, nextFlowXco)];
                transLength = transLength + 1;
            else
                flow.stopped = true; % Deposit when the flow velocity has dropped below the designated threshold
                fprintf("Low-slope %5.4f (%3.2f) ", flow.velocity, glob.deposVelocity);
                apexType = 2;
                erodeThick = 0; %added by IB
            end
        end
        
        % NEW: append event code for this step (0/1/2) to the tracker
        glob.track_route{glob.it}(end+1) = eventCode;
        glob.erodeThick_route{glob.it}(end+1) = erodeThick;
        glob.flowRate_route{glob.it}(end+1)     = flowRate;
        glob.flowTime_route{glob.it}(end+1)     = flowTime;
        glob.topogErode_route{glob.it}(end+1)     = topogErode;

        
        iterations = iterations + 1; 
    end
    
    flow.apexCoords(1:4) = [apexType, nextFlowXco, nextFlowYco, topog(nextFlowYco, nextFlowXco)];
    
    fprintf("Obst depos %1.0f (%7.6f) %d points %4.3f m ", obstDeposVol, obstDeposVol / flow.totalVolume, obstDeposCount, obstDeposVol / (glob.dx * glob.dy));

    if randomRouting 
        fprintf("Warning - stochastic element used in steepest descent routing - no unique lowest destination cell");
    end
    
    if iterations >= iterationLimit
        fprintf("\nWarning - steepest descent algorithm reached maximum iteration limit of %d\n", iterationLimit)
        fprintf("Likely due to flow trapping in topo low around x=%d y=%d\n", prevFlowXco, prevFlowYco);
    end
end


