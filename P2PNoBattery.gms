Sets
      i   Houses   / 1*3 /
      t   Time     /1*2/
Alias (i, j);
*Sets
*      P2Ptrade(i,j) 'exclude diagonal';
*      P2Ptrade(i,j) = yes;
*      P2Ptrade(i,i) = no;

*display P2Ptrade;

Scalar
psip2p /0.924/;

Parameters
      Pg(t)  Spot Price
          / 1   1
            2   3 /
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
;

Equations
     cost             define objective function
*     Timport(t,i)     Total import
*     Texport(t,i)     Total export
     Bal(t,i)         Balance equation
     P2P(t,i,j)
;

cost ..         z  =e=   sum(t,Pg(t)*sum(i,G(t,i)));
*Timport(t,i)..  I(t,i) =e= sum(j,Ip2p(t,i,j));
*Texport(t,i)..  X(t,i) =e= sum(j,Xp2p(t,i,j));
Bal(t,i)..      RES(t,i)+G(t,i)+sum(j $ (ord(i) <> ord(j)),Ip2p(t,i,j)) =g= DEM(t,i)+ sum(j $ (ord(i) <> ord(j)),Xp2p(t,i,j));
P2P(t,i,j)..    Ip2p(t,i,j) $ (ord(i) <> ord(j)) =e= psip2p*Xp2p(t,j,i) $ (ord(i) <> ord(j));

Model Test1 / all/;
solve Test1 using LP minimizing z;









