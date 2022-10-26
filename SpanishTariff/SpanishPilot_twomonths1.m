clc
clear
%%
EnergyCost=xlsread('TwoMonths.xlsx',5,'B1:B6');
PowerCost=xlsread('TwoMonths.xlsx',6,'B1:B6');
Feedin_cost=xlsread('TwoMonths.xlsx',7,'B1:B6');
ET = xlsread('TwoMonths.xlsx',4,'B2:Y13');
EVdata=xlsread('TwoMonths.xlsx',8,'B1:B8');

% D=1; 
for D=[1:11, 13:66]
tf=(D-1)*96+1;
tt=D*96;

dem = xlsread('TwoMonths.xlsx',1,strcat('C',num2str(tf),':H',num2str(tt)));
dem(:,7:12) = xlsread('TwoMonths.xlsx',2,strcat('C',num2str(tf),':H',num2str(tt)));
RES = xlsread('TwoMonths.xlsx',3,strcat('C',num2str(tf),':H',num2str(tt)));
% res=[zeros(size(dem)), RES];
res=[RES/4 RES/4 RES/4 RES/4 zeros(length(dem(:,1)),length(dem(1,:))-4+1)];
dem = [dem zeros(length(dem(:,1)),1)];
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
% [linsolEV_S_PV(D).dec,fvalEV_S_PV(D,1)]=p2p_EV_Separate_PV_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour, ATS, DTS, Nev, Cap_perEV, CHrate,DCHrate,arrSoC,DepSoC);
disp(D)
disp('*****************')
end

%% Analysis, KPIs
clc
clear
load('C:\Naser\Projects\BEYOND_P2P_PF\Spanish Case\result\fval.mat')
load('C:\Naser\Projects\BEYOND_P2P_PF\Spanish Case\result\fval_nop2p.mat')
load('C:\Naser\Projects\BEYOND_P2P_PF\Spanish Case\result\fvalEV.mat')
load('C:\Naser\Projects\BEYOND_P2P_PF\Spanish Case\result\linsol.mat')
load('C:\Naser\Projects\BEYOND_P2P_PF\Spanish Case\result\linsol_nop2p.mat')
load('C:\Naser\Projects\BEYOND_P2P_PF\Spanish Case\result\linsolEV.mat')
dem(:,1:6) = xlsread('TwoMonths.xlsx',1,'C1:H6336');
dem(:,7:12) = xlsread('TwoMonths.xlsx',2,'C1:H6336');
dem(isnan(dem))=0;
RES = xlsread('TwoMonths.xlsx',3,'C1:C6336');
RES(isnan(RES))=0;
%%  
clc
Tcost1=sum(fval_nop2p)
Tcost2=sum(fvalEV)
(Tcost1-Tcost2)/Tcost1

Peak1=zeros(6,1);
Peak2=zeros(6,1);
P11=[];
P22=[];
for D=[1:11, 13:66]
    G1((D-1)*96+1:D*96,:)=linsol_nop2p(D).dec.G;
    G2((D-1)*96+1:D*96,:)=linsolEV(D).dec.G;
    P1=linsol_nop2p(D).dec.Peak;
    Peak1=max(Peak1,P1);
    P11=[P11;P1];
    P2=linsolEV(D).dec.Peak;
    Peak2=max(Peak2,P2);
    P22=[P22;P2];
end    
Peak1=Peak1*4
Peak2=Peak2*4

sum(sum(dem))/4

Gt1=sum(sum(G1))/4

Gt2=sum(sum(G2))/4
(Gt1-Gt2)/Gt1

max(sum(G1,2))*4
max(sum(G2,2))*4

plot(P11*4)
hold on
plot(P22*4,'r')

figure
plot(sum(G1,2),'b','Linewidth',1)
hold on
plot(sum(G2,2),'r','Linewidth',1)

legend('No sharing','sharing')

xlabel('Time step (15 min)')
ylabel('Energy consumption [kWh]')

xlim([1153 1440])
