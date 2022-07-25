"""
Created on Sun Mar  7 17:41:17 2021

@author: seyednh
"""

from pyomo.environ import *
import pandas as pd
import numpy as np
from pyomo.opt import SolverFactory
import pyomo as pyo


# address = 'C:\Users\Mousa\PycharmProjects\Pyomo\InputData.xlsx'


BatteryPlace=np.array([1, 1, 0, 1]);

def InputParam(address):
    DemDF = pd.read_excel(address, sheet_name='Demand_houses')
    Dem = DemDF.to_numpy()

    WindDF = pd.read_excel(address, sheet_name='Wind_input')
    Wind = WindDF.to_numpy()

    PVDF = pd.read_excel(address, sheet_name='PV_input')
    PV = PVDF.to_numpy()

    PgDF = pd.read_excel(address, sheet_name='Elec_price')
    Pg = PgDF.to_numpy()
    Pg = dict(enumerate(Pg.flatten(), 0))
    print(type(Pg))

    RES = PV + Wind
    Nh = len(Dem[0, :])
    Nt = len(Dem[:, 0])
    
    Battery_DF = pd.read_excel(address, sheet_name='Battery_input')
    BatteryInput = Battery_DF.to_numpy()
    
    
    
    return Dem, Pg, RES, Nh, Nt, BatteryInput


Dem, Pg, res, Nh, Nt, BatteryInput = InputParam('C:/Naser/Python Book/P2PMarket/InputData p.xlsx')
#Dem, Pg, res, Nh, Nt, BatteryInput = InputParam('C:/Naser/Python Book/P2PMarket/InputData25Houses.xlsx')

Battery_Ub=BatteryInput[0];
Battery_Lb=BatteryInput[1];
Battery_ChargeRate=BatteryInput[2];
Battery_disChargeRate=BatteryInput[3];
Battery_ChargeEff=BatteryInput[4];
Battery_disChargeEffb=BatteryInput[5];

#%%

model = ConcreteModel()

# Define model Parameters
model.Nh = RangeSet(0, Nh-1, 1)
model.Np = RangeSet(0, Nh - 2, 1)
model.Nt = RangeSet(0, Nt-1, 1)


# declare decision variables
model.G = Var(model.Nt, model.Nh, domain=NonNegativeReals)
model.X_p = Var(model.Nt, model.Nh, model.Np, domain=NonNegativeReals)
model.I_p = Var(model.Nt, model.Nh, model.Np, domain=NonNegativeReals)


if sum(BatteryPlace)>0:
   model.Bat = RangeSet(0, sum(BatteryPlace)-1, 1)

   model.C = Var(model.Nt, model.Bat, domain=NonNegativeReals, bounds=(0,Battery_ChargeRate))
   model.D = Var(model.Nt, model.Bat, domain=NonNegativeReals, bounds=(0,Battery_disChargeRate))
   model.S = Var(model.Nt, model.Bat, domain=NonNegativeReals, bounds=(Battery_Lb,Battery_Ub))



#%%
# declare objective
def obj_rule(model):
    return sum(Pg[t] * model.G[t, h] for h in model.Nh for t in model.Nt)

model.obj = Objective(rule=obj_rule, sense=minimize)
#%%
PsiP2P = 1 - 0.076
IXpind = np.zeros([Nh - 1, Nh],dtype=int)
for i in range(Nh):
    for j in range(Nh - 1):
        if i <= j:
            IXpind[j, i] = j + 1
        else:
            IXpind[j, i] = j 

model.P2P = ConstraintList()
k=-1
for i in model.Nh:
    if BatteryPlace[i]!=0:
      k=k+1
      
      model.P2P.add(model.S[0,k]==0+Battery_ChargeEff*model.C[0,k] - (1/Battery_disChargeEffb)*model.D[0,k])
      #model.P2P.add(model.S[Nt-1,k]==1)
      for t in range(1,Nt):
          model.P2P.add(model.S[t,k]==model.S[t-1,k] + Battery_ChargeEff*model.C[t,k] - (1/Battery_disChargeEffb)*model.D[t,k])
          
      
      
      for t in model.Nt:
         model.P2P.add(res[t,i]+model.G[t,i] + model.D[t,k] +sum(model.I_p[t,i,j] for j in model.Np)>=Dem[t,i]+ model.C[t,k]+sum(model.X_p[t,i,j] for j in model.Np))
         for j in model.Np:
             b=np.asarray(np.where(IXpind[:,IXpind[j,i]] == i))
             model.P2P.add(model.I_p[t, i, j] == PsiP2P * model.X_p[t, IXpind[j, i] ,b[0,0]])
             
    elif BatteryPlace[i]==0:
        for t in model.Nt:
           model.P2P.add(res[t,i]+model.G[t,i]+sum(model.I_p[t,i,j] for j in model.Np)>=Dem[t,i]+sum(model.X_p[t,i,j] for j in model.Np))
           for j in model.Np:
               b=np.asarray(np.where(IXpind[:,IXpind[j,i]] == i))
               model.P2P.add(model.I_p[t, i, j] == PsiP2P * model.X_p[t, IXpind[j, i] ,b[0,0]])
        

#%%         
'''
def con_rule(model, Nh):
   PsiP2P = 1 - 0.076
   IXpind = np.zeros([Nh - 1, Nh],dtype=int)
   for i in range(Nh):
       for j in range(Nh - 1):
           if i <= j:
               IXpind[j, i] = j + 1
           else:
               IXpind[j, i] = j 
   
   model.P2P = ConstraintList()
   for i in model.Nh:
       if BatteryPlace[i]!=0:
         for t in model.Nt:
            model.P2P.add(res[t,i]+model.G[t,i]+sum(model.I_p[t,i,j] for j in model.Np)>=Dem[t,i]+sum(model.X_p[t,i,j] for j in model.Np))
            for j in model.Np:
                b=np.asarray(np.where(IXpind[:,IXpind[j,i]] == i))
                model.P2P.add(model.I_p[t, i, j] == PsiP2P * model.X_p[t, IXpind[j, i] ,b[0,0]])
'''    




#%%
#results = SolverFactory("GLPK", Verbose=True).solve(model,tee=True)

model.pprint()

#%%
#opt = SolverFactory('glpk')
#opt.solve(model)

#%%
opt = SolverFactory('glpk')
opt.solve(model) 



#%%
for key in model.G:
    print(value(model.G[key]))
    
value(model.obj)

#%%
'''
for key in model.C:
    print(value(model.C[key]))

for key in model.D:
    print(value(model.D[key]))
    
for key in model.I_p:
    print(value(model.I_p[key]))

for key in model.X_p:
    print(value(model.X_p[key]))
#%%
'''