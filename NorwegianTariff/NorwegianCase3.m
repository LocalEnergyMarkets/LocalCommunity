clc
clear

% EUROtoNOK = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\aprTaug2021.xlsx",4,"F5:F5");
% Dem = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\aprTaug2021.xlsx",1,"B2:H721");  % April
% RES = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\aprTaug2021.xlsx",3,"B2:H721");
% Sprice = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\aprTaug2021.xlsx",4,"C2:C721"); % Euro/MWh
% Sprice = Sprice * EUROtoNOK/1000; % NOK/kWh
% En_price = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\aprTaug2021.xlsx",4,"F1:F1"); % øre/kWh
% En_price = En_price * 0.01; % NOK/kWh
% Marginal_LR = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\aprTaug2021.xlsx",4,"F4:F4");

EUROtoNOK = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\OneYear2021.xlsx",4,"F5:F5");
Dem = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\OneYear2021.xlsx",1,"B2162:H4345");  % April
RES = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\OneYear2021.xlsx",3,"B2162:H4345");
Sprice = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\OneYear2021.xlsx",4,"C2:C2185"); % Euro/MWh
Sprice = Sprice * EUROtoNOK/1000; % NOK/kWh
En_price = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\OneYear2021.xlsx",4,"F1:F1"); % øre/kWh
En_price = En_price * 0.01; % NOK/kWh
Marginal_LR = xlsread("C:\\Naser\\Projects\\BEYOND_P2P_PF\\Norwegian case\\DemandProfiles\\OneYear2021.xlsx",4,"F4:F4");

load('EV_departureTime.mat')
load('EVarrivalTime.mat')
EV_dr = EV_dr(90+1:90+91,2);  % The second EV profile - April to June
EV_ar = EV_ar(90+1:90+91,2);  % The second EV profile - April to June

Pr = Sprice + En_price;
EVPlace = [0,0,0,0,1,0,0];
EVcap=50;
EValpha=20;
EVbeta=20;


etaEV_ch=0.98;
etaEV_dis=0.98;
Nt=24;
%%
% DAY = 91;
for DAY = 1:91
    dts=EV_dr(DAY);
    ats=EV_ar(DAY);
    dem=Dem((DAY-1)*Nt+1:DAY*Nt,:);
    res=RES((DAY-1)*Nt+1:DAY*Nt,:);
    Pg=Pr((DAY-1)*Nt+1:DAY*Nt,:);
    arrivalSoC = (rand(sum(EVPlace),1)*(0.45-0.35)+0.35)*EVcap;
    DepartureSoC = (0.7*ones(sum(EVPlace),1))*EVcap;
    %%
    [linsol_Nores(DAY).s,fval_Nores(DAY,1)]=Nop2pEV(dem,zeros(size(dem)),Marginal_LR, Pg, En_price, Nt, EVPlace, EValpha, EVbeta, EVcap, ats,dts,arrivalSoC, DepartureSoC, etaEV_ch, etaEV_dis);

    [linsol_Nop2p(DAY).s,fval_Nop2p(DAY,1)]=Nop2pEV(dem,res,Marginal_LR, Pg, En_price, Nt, EVPlace, EValpha, EVbeta, EVcap, ats,dts,arrivalSoC, DepartureSoC, etaEV_ch, etaEV_dis);
    [linsol(DAY).s,fval(DAY,1)]=p2pEV(dem,res,Marginal_LR, Pg, En_price, Nt, EVPlace, EValpha, EVbeta, EVcap, ats,dts, arrivalSoC, DepartureSoC, etaEV_ch, etaEV_dis);
end

