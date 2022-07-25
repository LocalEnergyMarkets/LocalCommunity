using JuMP
using XLSX
using HiGHS
##
address="C:/Naser/Python Book/P2PMarket/InputData25Houses.xlsx"
BatteryPlace=[0 0 1];
##
function InputParam(address)
xf = XLSX.readxlsx(address);
Demand_houses = xf["Demand_houses"];
Wind_input = xf["Wind_input"];
PV_input = xf["PV_input"];
Elec_price = xf["Elec_price"];
Dem = Demand_houses["B2:D49"];
Wind = Wind_input["B2:D49"];
PV = PV_input["B2:D49"];
Pg = Elec_price["B2:B49"];
RES=PV+Wind;
Nt=length(Dem[:,1]);
Nh=length(Dem[1,:]);

Ψp2p=1-0.076;
IXpind=zeros(Int16,Nh-1,Nh);
for i=1:length(IXpind[1,:])
    for j=1:length(IXpind[:,1])
        if i<=j
            IXpind[j,i]=j+1;
        else
            IXpind[j,i]=j;
        end
    end
end
return Dem, RES, Pg, Nh, Nt, Ψp2p, IXpind
end
##
function CommunityModel(Nh,Nt,BatteryPlace,Pg,RES,Dem, Ψp2p, IXpind)

model = Model(HiGHS.Optimizer);
@variable(model, G[1:Nt,1:Nh]>=0);
@variable(model, 0<=Ip2p[1:Nt,1:Nh,1:Nh-1]);
@variable(model, 0<=Xp2p[1:Nt,1:Nh,1:Nh-1]);
ex = @expression(model, sum(Pg'*G));
@objective(model, Min, ex);
I=sum(Ip2p,dims=3);
X=sum(Xp2p,dims=3);
indsNoBat = Tuple.(findall(x->x==0, BatteryPlace));
Nobat = last.(indsNoBat);
@constraint(model, Bal[i in Nobat], RES[:,i]+G[:,i]+I[:,i].>=Dem[:,i]+X[:,i]);
@constraint(model, P2Pcon[i = 1:Nh, j = 1:Nh-1], Ip2p[:,i,j].==Ψp2p*Xp2p[:,IXpind[j,i],findall(x->x==i, IXpind[:,IXpind[j,i]])]);
@constraint(model, Community, Ψp2p*sum(X,dims=2).==sum(I,dims=2));
return model,G,Ip2p,Xp2p,Bal,P2Pcon,Community
end
##
function BatteryModel(Nh,Nt,BatteryPlace,G,Ip2p,Xp2p,RES,Dem,address)
    xf = XLSX.readxlsx(address);
    Battery_input=xf["Battery_input"];
    Battery_Ub=Battery_input["B2"];
    Battery_Lb=Battery_input["B3"];
    Battery_ChargeRate=Battery_input["B4"];
    Battery_disChargeRate=Battery_input["B5"];
    Battery_ChargeEff=Battery_input["B6"];
    Battery_disChargeEff=Battery_input["B7"];
    InitialSoC=[0 0 0];
    Spp0=BatteryPlace.*InitialSoC;
    S0=Spp0[findall(x->x==1, BatteryPlace)];   # Initial SoC for the existing batteries
@variable(model, 0<=D[1:Nt,1:sum(BatteryPlace)]<=Battery_disChargeRate);
@variable(model, 0<=C[1:Nt,1:sum(BatteryPlace)]<=Battery_ChargeRate);
@variable(model, Battery_Lb<=S[1:Nt,1:sum(BatteryPlace)]<=Battery_Ub);
@constraint(model, SoC0, S[1,:].==S0+Battery_ChargeEff*C[1,:]-(1/Battery_disChargeEff)*D[1,:]);
@constraint(model, SoC[i = 1:Nt-1], S[i+1,:].==S[i,:]+Battery_ChargeEff*C[i+1,:]-(1/Battery_disChargeEff)*D[i+1,:]);
I=sum(Ip2p,dims=3);
X=sum(Xp2p,dims=3);
indsBat = Tuple.(findall(x->x==1, BatteryPlace));
bat = last.(indsBat);
@constraint(model, batBal[i in bat], RES[:,i]+G[:,i]+I[:,i]+D[:,sum(BatteryPlace[1:i])].>=Dem[:,i]+X[:,i]+C[:,sum(BatteryPlace[1:i])]);
return D, C, S,SoC0,SoC,batBal
end
##
Dem, RES, Pg, Nh, Nt, Ψp2p, IXpind=InputParam(address);
##
model,G,Ip2p,Xp2p,Bal,P2Pcon,Community=CommunityModel(Nh,Nt,BatteryPlace,Pg,RES,Dem, Ψp2p, IXpind);
##

D, C, S,SoC0,SoC,batBal=BatteryModel(Nh,Nt,BatteryPlace,G,Ip2p,Xp2p,RES,Dem,address);
##
@time optimize!(model);
OF=objective_value(model)

#print(model)
