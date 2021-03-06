function nonlinear = setNonlinearSolverParameters_JandG(maxIteration)

    nonlinear.maxIterations = maxIteration;
    % Relaxation parameters for Newton iterations
    nonlinear.relaxation  = 1;
    nonlinear.relaxMax    = 0.2;
    nonlinear.relaxInc    = 0.1;
    nonlinear.relaxRelTol = 0.01; %.1;
    
    % Parameters for Newton's iterations
    nonlinear.linesearch = false;
    
    nonlinear.relaxType = 'sor';
    nonlinear.tol = 1.0e-10;
end