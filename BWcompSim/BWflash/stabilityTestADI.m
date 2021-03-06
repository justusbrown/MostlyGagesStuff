function [stability_flag_l,stability_flag_g,stability_flag,Zgas_vap,Zgas_liq] = stabilityTestADI(mixture, thermo)
% Michelsen stability test; I have used the algorithm described here:
% https://www.e-education.psu.edu/png520/m17_p7.html

trivial_eps = 1e-4;
convergence_eps = 1e-10;
max_itr = 2000;

% extract EOS function
eosf = thermo.EOS_ADI;

% switch on the fugacity calculation in thermo structure
thermo.fugacity_switch=1; % switch on

% initialize pseudo second phases
gasmixture = mixture;
liquidmixture = mixture;
gasthermo = thermo;
gasthermo.phase = 2;
liquidthermo = thermo;
liquidthermo.phase = 1;

% extract the total composition and pressure
composition = mixture.Zi;
p = mixture.pressure;

% --------------------------- FIRST TEST ----------------------------------
% calculate the fugacity of the mixture, assuming it is a liquid
[fug_coef,Zgas_vap,Zgas_liq]=eosf(mixture, liquidthermo);
compXp=composition*p;
mixfug = fug_coef.*compXp.val; %[Pa]

% Initial estimate for k-values using an empirical equation
ki = wilsonCorrelationADI(mixture);

% assign large number to error values to begin the loop
conv_error = 1+convergence_eps;
triv_error = 1+trivial_eps;
j = 0;
%Added max***** to next line because conv_error is a 1x6 vector after first
%iter and needs to be a scalar. Check blackoilmodel and see what everything
%is supposed to be at each line
while (max(conv_error)>convergence_eps) && (triv_error>trivial_eps) && (j<max_itr)
    j = j+1; % loop counter
    % create a vapor-like second phase
    Yi = composition.*ki;
    SV = sum(Yi);

    % normalize the vapor-like mole fractions
    yi = Yi/SV.val;

    % calculate the fugacity of the vapor-like phase using the thermo structure
    gasmixture.Zi = yi;
    [fug_coef,Zgas_vap,Zgas_liq]=eosf(gasmixture, gasthermo);
    yiXp=yi*p;
    gasfug = fug_coef.*yiXp.val; %[Pa]

    % correct K-values
    Ri = mixfug./gasfug/SV.val; %I DONT THINK Ri IS SUPPOSED TO BE 6x6. I THINK IT SHOULD BE 1x6. VERIFY THIS WITH blackoilmodel
    ki = ki.*Ri;

    % calculate the convergence and trivial solution error values
    conv_error = sum((Ri-1).^2);
    triv_error = sum(log(ki(ki>0)).^2);
end

% analyze the first test results
if triv_error <= trivial_eps 
    stability_flag_l = 1; % converged to trivial solution
elseif conv_error <= convergence_eps
    stability_flag_l = 2; % converged
else 
    stability_flag_l = 3; % maximum iteration reached
end

% --------------------------- SECOND TEST ---------------------------------
% calculate the fugacity of the mixture, assuming it is a gas
[fug_coef,Zgas_vap,Zgas_liq]=eosf(mixture, gasthermo);
mixfug = fug_coef.*composition*p; %[Pa]

% Initial estimate for k-values using an empirical equation
ki = wilsonCorrelation(mixture);

% assign large number to error values to begin the loop
conv_error = 1+convergence_eps;
triv_error = 1+trivial_eps;
j = 0;
while (conv_error>convergence_eps) && (triv_error>trivial_eps) && (j<max_itr)
    j = j+1; % loop counter
    % create a liquid-like second phase
    Xi = composition./ki;
    SL = sum(Xi);

    % normalize the liquid-like mole fractions
    xi = Xi/SL;

    % calculate the fugacity of the liquid-like phase using the thermo structure
    liquidmixture.Zi = xi;
    [fug_coef,Zgas_vap,Zgas_liq]=eosf(liquidmixture, liquidthermo);
    liquidfug = fug_coef.*xi*p; %[Pa]

    % correct K-values
    Ri = liquidfug./mixfug*SL;
    ki = ki.*Ri;

    % calculate the convergence and trivial solution error values
    conv_error = sum((Ri-1).^2);
    triv_error = sum(log(ki(ki>0)).^2);
end

% analyze the second test results
if triv_error <= trivial_eps 
    stability_flag_g = 1; % converged to trivial solution
elseif conv_error <= convergence_eps
    stability_flag_g = 2; % converged
else 
    stability_flag_g = 3; % maximum iteration reached
end


%======================================================================
%interpretation of final results

if stability_flag_g==1 && stability_flag_l ==1
    stability_flag = 1 ; %which is stable
elseif (stability_flag_g==1 && stability_flag_l==3) || (stability_flag_g==3 && stability_flag_l==1) || (stability_flag_g==3 && stability_flag_l==3)
    stability_flag = 2 ; % which is unknown,since it exceeds the maximum iteration
elseif stability_flag_g==3 || stability_flag_l ==3
    switch stability_flag_g
        case 3
            S = SV;
        case 2
            S = SL;
    end
    if S > 1
        stability_flag = 0; % which is unstable
    else
        stability_flag = 2; % which we are not sure because the other phase exceeded max_iter, it may be either > or < = 1 
    end 
else
    if stability_flag_g ==1 && stability_flag_l==2
         S = SV;
    elseif stability_flag_g ==2 && stability_flag_l==1
        S = SL;
    else
        S = max (SL,SV);
    end
    if S > 1
        stability_flag = 0; % which is unstable
    else
        stability_flag = 1; % which is stable
    end 
end

end
