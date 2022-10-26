clc
clear
%%
EnergyCost=xlsread('TwoMonths.xlsx',5,'B1:B6');
PowerCost=xlsread('TwoMonths.xlsx',6,'B1:B6');
Feedin_cost=xlsread('TwoMonths.xlsx',7,'B1:B6');
ET = xlsread('TwoMonths.xlsx',4,'B2:Y13');
EVdata=xlsread('TwoMonths.xlsx',8,'B1:B8');

% D=1; [1:11, 13:66]
for D=1:2
tf=(D-1)*96+1;
tt=D*96;

dem = xlsread('TwoMonths.xlsx',1,strcat('C',num2str(tf),':H',num2str(tt)));
dem(:,7:12) = xlsread('TwoMonths.xlsx',2,strcat('C',num2str(tf),':H',num2str(tt)));
RES = xlsread('TwoMonths.xlsx',3,strcat('C',num2str(tf),':H',num2str(tt)));
% res=[zeros(size(dem)), RES];
res=[RES/4 RES/4 RES/4 RES/4 zeros(length(dem(:,1)),length(dem(1,:))-4)];
% dem = [dem zeros(length(dem(:,1)),1)];
Month=xlsread('TwoMonths.xlsx',9,strcat('A',num2str(tf),':A',num2str(tt)));
month=Month(2);
%%
ET3=ET(month,:);
PgET3=zeros(length(ET3),1);
Pf=zeros(length(ET3),1);
for i=1:length(ET3)
    PgET3(i)=EnergyCost(ET3(i));
    Pf(i)=Feedin_cost(ET3(i));
end

ATS=EVdata(1);
DTS=EVdata(2);
Nev=EVdata(3);
Cap_perEV=EVdata(4);
CHrate=EVdata(5);
DCHrate=EVdata(6);
arrSoC=EVdata(7);
DepSoC=EVdata(8);

TimeStepperHour=4;
Pe=repelem(PgET3,TimeStepperHour);
Pf=repelem(Pf,TimeStepperHour);
ET3=repelem(ET3,TimeStepperHour);
Nt=length(Pe);


psip2p=0.99999;      %1-0.076;  Because the model has a feed-in cost, we do not apply losses o the  model.

[linsol_nop2p(D).dec,fval_nop2p(D,1)]=Nop2p_EV_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour, ATS, DTS, Nev, Cap_perEV, CHrate,DCHrate,arrSoC,DepSoC);

[linsol(D).dec,fval(D,1)] = p2p_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour);
[linsolEV(D).dec,fvalEV(D,1)]=p2pEV_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour, ATS, DTS, Nev, Cap_perEV, CHrate,DCHrate,arrSoC,DepSoC);
[linsolEV_S_PV(D).dec,fvalEV_S_PV(D,1)]=p2p_EV_Separate_PV_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour, ATS, DTS, Nev, Cap_perEV, CHrate,DCHrate,arrSoC,DepSoC);
disp(D)
disp('*****************')
end

%% Analysis, KPIs
clc
clear
load('fval_nop2p.mat')
load('linsol_nop2p.mat')
load('linsol.mat')
load('linsolEV.mat')
load('linsolEV_S_PV.mat')
load('fval.mat')
load('fvalEV.mat')
load('fvalEV_S_PV.mat')
dem(:,1:6) = xlsread('TwoMonths.xlsx',1,'C1:H6336');
dem(:,7:12) = xlsread('TwoMonths.xlsx',2,'C1:H6336');
dem(isnan(dem))=0;
%%  
clc
Tcost=sum(fval)
TcostEV=sum(fvalEV_S_PV)



for D=[1:11, 13:66]
    G((D-1)*96+1:D*96,:)=linsol(D).dec.G;
    Gev((D-1)*96+1:D*96,:)=linsolEV_S_PV(D).dec.G;
end    


sum(sum(dem))

sum(sum(G))

sum(sum(Gev))













