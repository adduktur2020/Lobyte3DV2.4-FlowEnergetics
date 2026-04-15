function [depos, erodedTopog, erodedThickness] = calcErodeStrataIB2(glob, depos, topog, erosionMap, x,y)
    
    % 1. Get Inputs
    potentialErosionDepth = erosionMap(y,x); 
    basementElevation = depos.elevation(y,x,1);
    currentElevation = topog(y,x);
    
    % 2. Calculate Soft Sediment (anything above original basement)
    softSedimentThickness = max(0, currentElevation - basementElevation);
    
    % 3. Apply "Soft vs. Hard" Logic to get the FINAL eroded topography
    if potentialErosionDepth <= softSedimentThickness
        % --- CASE 1: EASY EROSION (Soft Sediment Only) ---
        erodedTopog = currentElevation - potentialErosionDepth;
    else
        % --- CASE 2: HARD EROSION (Hits the Basement) ---
        % Eats all soft sediment
        erosionOfSoftSediment = softSedimentThickness;
        
        % "Leftover" potential for hard basement
        erosionIntoBasement_potential = potentialErosionDepth - softSedimentThickness;
        
        % "Taxed" actual hard erosion
        % erosionOfHardSediment = erosionIntoBasement_potential * glob.basementErodibility;
        erosionOfHardSediment = erosionIntoBasement_potential * 0.5;
        
        % Final topography
        erodedTopog = currentElevation - erosionOfSoftSediment - erosionOfHardSediment;
    end
    
    % 4. Calculate the TOTAL physical erosion
    % This is the only "erodedThickness" we need.
    erodedThickness = currentElevation - erodedTopog; 
    
    % 5. Truncate all buried surfaces
    for t = glob.it:-1:2 
        if erodedTopog < depos.elevation(y,x,t) 
            depos.elevation(y,x,t) = erodedTopog; 
        end  
    end
    
    % 6. "Accounting" Loop
    % This loop MUST run using the *total* erodedThickness.
    % It will "eat" its way down. It will correctly eat the
    % hpThickness and transThickness for it=11, 10, 9...
    % and when it hits chron=1, it will stop. This is
    % mass-conservative and correct.
    chron = glob.it;
    thicknessLeftToErode = erodedThickness; 
    
    while thicknessLeftToErode > 0 && chron > 1
        % --- This accounting loop is now correct ---
        
        if depos.hpThickness(y,x,chron) < thicknessLeftToErode 
            thicknessLeftToErode = thicknessLeftToErode - depos.hpThickness(y,x,chron);
            depos.hpThickness(y,x,chron) = 0;
        else
            depos.hpThickness(y,x,chron) = depos.hpThickness(y,x,chron) - thicknessLeftToErode; 
            thicknessLeftToErode = 0; 
        end

        if depos.transThickness(y,x,chron) < thicknessLeftToErode 
            thicknessLeftToErode = thicknessLeftToErode - depos.transThickness(y,x,chron);
            depos.transThickness(y,x,chron) = 0;
            depos.facies(y,x,chron) = 10; 
        else
            depos.transThickness(y,x,chron) = depos.transThickness(y,x,chron) - thicknessLeftToErode;
            thicknessLeftToErode = 0;
        end 

        chron = chron - 1;
    end
end