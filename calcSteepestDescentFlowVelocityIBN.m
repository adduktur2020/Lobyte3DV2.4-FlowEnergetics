function [flowVelocity, flowShearVelocity] = calcSteepestDescentFlowVelocityIBN(glob, gradient, flowVelocity, flowShearVelocity, C)
% Calculate the maximum flow velocity and shear velocity at point xco,
% based on topographic gradient and sediment concentration using flow density, basal shear stress

    gradient = rad2deg(atan(gradient)); % Convert gradient to degrees, as required by following equations
    rhoFlow = (2.6 * C) + (1 - C); % rhoFlow is the flow bulk density
    flowDensity = ((rhoFlow - glob.rhoAmbient) / glob.rhoAmbient); % R is submerged flow density
    maxShearVelocity = sqrt( glob.gravity * flowDensity .* abs(gradient) * 0.25 * glob.totalFlowThickness) * sign(gradient); % (m/s) Shear Velocity calculation, including sign indicating downslope direction
    maxVelocity = maxShearVelocity / sqrt(glob.basalFrictCoeff);   % (m/s) this converts shear velocity into velocity (Stevenson grand banks paper)
    
    flowAcceleration = maxVelocity - flowVelocity;
    flowShearAcceleration =  maxShearVelocity - flowShearVelocity;

    if flowVelocity < maxVelocity || flowVelocity > maxVelocity
        flowVelocity = flowVelocity + (flowAcceleration * glob.flowAccelProportion);
        flowShearVelocity  = flowShearVelocity + (flowShearAcceleration * glob.flowAccelProportion);
    end  
end