clc
clear
%%
EnergyCost=xlsread('TwoMonths.xlsx',5,'B1:B6');
PowerCost=xlsread('TwoMonths.xlsx',6,'B1:B6');
Feedin_cost=xlsread('TwoMonths.xlsx',7,'B1:B6');

Day=1;


MONTH=xlsread('TwoMonths.xlsx',9,'A1:A6324');
month=1;



dem = xlsread('TwoMonths.xlsx',1,'C1:H96');
dem(:,7:12) = xlsread('TwoMonths.xlsx',2,'C1:H96');
RES = xlsread('TwoMonths.xlsx',3,'C1:C96');




res=[zeros(size(dem)), RES];
dem = [dem zeros(length(dem(:,1)),1)];
ET = xlsread('TwoMonths.xlsx',4,'B2:Y13');
EVdata=xlsread('TwoMonths.xlsx',8,'B1:B8');

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


psip2p=0.99999;      %1-0.076;


[linsol,fval] = p2p_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour)
[linsolEV,fvalEV]=p2pEV_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour, ATS, DTS, Nev, Cap_perEV, CHrate,DCHrate,arrSoC,DepSoC)
[linsolEV_S_PV,fvalEV_S_PV]=p2p_EV_Separate_PV_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour, ATS, DTS, Nev, Cap_perEV, CHrate,DCHrate,arrSoC,DepSoC)
