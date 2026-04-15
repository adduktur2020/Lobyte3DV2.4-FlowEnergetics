function gprime = calcReducedGravity(glob, C)
% C is the current step sediment volume concentration (0..1)
    rho_bulk = C * glob.rhoSolid + (1 - C) * glob.rhoAmbient;
    gprime   = glob.gravity * (rho_bulk - glob.rhoAmbient) / glob.rhoAmbient;
end
