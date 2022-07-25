Sets
      i   Houses   / 1*3 /

Bat(i)  Batteriy Nodes       /3/
      t   Time     /1*2/
      tstart(t)    /1/
      trest(t)     /2/
*      trest('1')  = no;

Alias (i, j);

Scalar
psip2p /0.924/;

Parameters
      Pg(t)  Spot Price
          / 1   1
            2   3 /
      InitialSoC(Bat)
          /3   0/
      Battery_ChargeEff(Bat)
          /3   0.98/
      Battery_disChargeEff(Bat)
          /3   1/
Table RES(t,i)
        1        2       3
    1   0.409    0       0.333
    2   0.447    0       0.328
Table DEM(t,i)
        1        2       3
    1   0.844    0.539   0.193
    2   1.643    0.479   0.184

Variables
     z
;
Positive Variables
     G(t,i)           Import from the main grid
     Ip2p(t,i,j)      P2P import
     Xp2p(t,i,j)      P2P Export
     D(t,i)
     C(t,i)
     S(t,i)
;
S.up(t,Bat)=4;
D.up(t,Bat)=1.2;
C.up(t,Bat)=1.2;



Equations
     cost             define objective function
     Bal(t,i)         Balance equation
     P2P(t,i,j)
     SOC(t,Bat)
;

cost ..            z  =e=   sum(t,Pg(t)*sum(i,G(t,i)));
Bal(t,i)..         RES(t,i)+G(t,i)+sum(j $ (ord(i) <> ord(j)),Ip2p(t,i,j))+ D(t,i)$(Bat(i)) =g= DEM(t,i)+ sum(j $ (ord(i) <> ord(j)),Xp2p(t,i,j))+ C(t,i)$(Bat(i));
P2P(t,i,j)..       Ip2p(t,i,j) $ (ord(i) <> ord(j)) =e= psip2p*Xp2p(t,j,i) $ (ord(i) <> ord(j));
SOC(t,Bat)..       S(t,Bat)=e= InitialSoC(Bat)$ ( ord ( t ) =1)+S(t-1,Bat)$ ( ord ( t ) >1)+Battery_ChargeEff(Bat)*C(t,Bat)-Battery_disChargeEff(Bat)*D(t,Bat);



Model Test1 / all/;
solve Test1 using LP minimizing z;



*                                          $ (s(i) and u(i) and t(i))





