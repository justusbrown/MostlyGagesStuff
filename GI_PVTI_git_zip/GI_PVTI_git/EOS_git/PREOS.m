function [fugacity_coef,Zgas_vap, Zgas_liq, success_flag] = PREOS(mixture, thermo)
% T and critical temperature in [K]
% P and critical pressure in [bar]
% HR in [J/mol]
success_flag = 1;
phase = thermo.phase;
fug_need = thermo.fugacity_switch;
critical_pres = [mixture.components.Pc]; %[Pa]
critical_temp = [mixture.components.Tc]; %[K]
acentric_fact = [mixture.components.acentric_factor]; %[-]
BIP = mixture.bip;
x = mixture.Zi;
p = mixture.pressure; %[Pa]
T = mixture.Temp;
N = length(critical_temp);
fugacity_coef = zeros(1,N);
R=8.3145;

bi = 0.077796*R*critical_temp./critical_pres;
aci=0.457235*(R*critical_temp).^2 ./critical_pres;
mi = 0.37646+(1.54226-0.26992*acentric_fact).*acentric_fact;
Tr = T./critical_temp;
alfai = 1+mi.*(1-sqrt(Tr));   %//alfai=ai^0.5
alfa = alfai.^2.0;           %//alfa=ai
ai = aci .* alfa;

[a,b] = simple_mixing_rule(mixture, thermo, ai, bi);
A_coef=a*p/(R*T)^2;
B_coef=b*p/(R*T);
poly_coef = [1 -1+B_coef A_coef-B_coef*(2.0+3*B_coef) -B_coef*(A_coef-B_coef*(1+B_coef))];
z_root = roots(poly_coef);
%---------------------------------------------------------------------
%root selection

z_root(find(imag(z_root)~=0))=[];
z_root(find(z_root<=b*p/(R*T))) = [];

num_root = length(z_root);

switch num_root
    case 0
       success_flag = 0;
       fug_need = 0;
       Zgas_vap=nan;
       Zgas_liq=nan;
    case 1
        zz = z_root(1);
        Zgas_vap=zz;
        Zgas_liq=zz;
    
    otherwise
        if phase == 2
           zz = max(z_root);
           Zgas_vap=zz;
           Zgas_liq=min(z_root);%I am not sure about this at all gr-7/19
        else
           zz = min(z_root);
           Zgas_vap=max(z_root);
           Zgas_liq=zz;
        end  
end

%--------------------------------------------------------------------------------
if (fug_need==1)
    part1=bi/b*(zz-1)-log(zz-b*p/(R*T));
    part2=x*(sqrt(ai'*ai).*(1-[BIP.EOScons]-[BIP.EOStdep]*T))';
    part3=A_coef/(2.828*B_coef)*(bi/b-2/a*part2) ...
        *log((zz+2.414*b*p/(R*T))/(zz-0.414*b*p/(R*T)));
    fugacity_coef=exp(part1+part3);
end

end





         
