function [depos, erodedTopog, erodedThickness] = calcErodeStrataIB(glob, depos, topog, erosionMap, x,y)

% Get the potential erosion depth calculated by calcFlowErosion
    potentialErosionDepth = erosionMap(y,x); 

    % Define the elevations we are working with
    basementElevation = depos.elevation(y,x,1);
    currentElevation = topog(y,x); % This is the surface the flow is running on
    
    % Calculate how much "soft" sediment (all deposits > t=1) is available
    softSedimentThickness = currentElevation - basementElevation;
    
    if potentialErosionDepth <= softSedimentThickness
        % --- CASE 1: EASY EROSION ---
        % The flow only erodes its own "soft" deposits.
        % This happens at 100% efficiency.
        erodedTopog = currentElevation - potentialErosionDepth;
        
    else
        % --- CASE 2: HARD EROSION (HITS THE BASEMENT) ---
        % The flow wants to erode *through* all the soft sediment
        % and *into* the hard basement.
        
        % 1. Calculate how much erosion is "left over" after
        %    eating all the soft sediment.
        erosionIntoBasement_potential = potentialErosionDepth - softSedimentThickness;
        
        % 2. Apply the "tax." Reduce the hard basement erosion
        %    by the erodibility factor.
        % erosionIntoBasement_actual = erosionIntoBasement_potential * glob.basementErodibility;
        erosionIntoBasement_actual = erosionIntoBasement_potential * 0.5;
        
        % 3. Calculate the new final topography.
        erodedTopog = basementElevation - erosionIntoBasement_actual;
    end


    % the erosion map at x,y contains the erosion the flow is capable of, but it can only erode if flowing over deposited strata, so chron>= 2
    % Therefore set the actual erosion to zero and update in the code below if actual erosion of chrons >= 2 has occurred
    
    % erodedTopog = topog(y,x) - erosionMap(y,x); % Not possible because
    % 
    % if erodedTopog < depos.elevation(y,x,1) % Check if the eroded topography height is less than the basement elevation at x,y
    %     erodedTopog = depos.elevation(y,x,1);
    % end
    
    erodedThickness = depos.elevation(y,x,glob.it)  - erodedTopog; % record the difference in elevation as the actual eroded thickness
    
    % Erode the elevation surfaces stored in deposElevation
    for t = glob.it:-1:2 % Loop through all chrons starting from current it/youngest, down to first chron (t=2)
        
        if erodedTopog < depos.elevation(y,x,t) % If chron t at x,y is above the eroded topography surface, erode chron t

            depos.elevation(y,x,t) = erodedTopog; % Erode chron t by setting elevation to the value of the eroded topography
        end  
    end

    % Now erode the layer thickness data
    chron = glob.it;
    thicknessLeftToErode = erodedThickness;
    while thicknessLeftToErode > 0 && chron > 1

        if depos.hpThickness(y,x,chron) < thicknessLeftToErode % Erosion > hemipelagic thickness, so erode all HP thickness
            thicknessLeftToErode = thicknessLeftToErode - depos.hpThickness(y,x,chron);
            depos.hpThickness(y,x,chron) = 0;
        else
            depos.hpThickness(y,x,chron) = depos.hpThickness(y,x,chron) - thicknessLeftToErode; % otherwise reduce Hp thickness by erosion magnitude
            thicknessLeftToErode = 0; % And set remaining erosion magnitude to zero
        end

        if depos.transThickness(y,x,chron) < thicknessLeftToErode % Erosion remaining to do > transported thickness, so erode all transported thickness
            thicknessLeftToErode = thicknessLeftToErode - depos.transThickness(y,x,chron);
            depos.transThickness(y,x,chron) = 0;
            depos.facies(y,x,chron) = 10; % Record completely eroded transported layer as facies = 10
        else
            depos.transThickness(y,x,chron) = depos.transThickness(y,x,chron) - thicknessLeftToErode;
            thicknessLeftToErode = 0;
        end 

        chron = chron - 1;
    end
 end