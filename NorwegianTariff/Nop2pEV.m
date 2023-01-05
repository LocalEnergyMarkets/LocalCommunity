function [linsol,fval]=Nop2pEV(dem,res,Marginal_LR, Pg, En_price, Nt, EVPlace, EValpha, EVbeta, EVcap, ats,dts,arrivalSoC, DepartureSoC, eta_ch, eta_dis)
EVavailability=zeros(Nt,1);
EVavailability(1:dts)=1;
EVavailability(ats:Nt)=1;
psip2p = 1-0.072;
N_EV = sum(EVPlace);
%,alpha,beta,Sl,Su,eta_ch,eta_dis,Nt,,BatteriPlace,S0,psip2p,EVcap,arrivalSoC,DepartureSoC,N_EV,EVbeta,EValpha,EVavailability,ats,dts)
Nh=length(dem(1,:));
%% defining variables
aa=size(dem);
G=optimvar('G',aa(1),aa(2),'LowerBound',0);
N=optimvar('N',aa(1),aa(2),'LowerBound',0);

% D=optimvar('D',Nt,sum(BatteriPlace),'LowerBound',0,'UpperBound',beta);
% C=optimvar('C',Nt,sum(BatteriPlace),'LowerBound',0,'UpperBound',alpha);
% S=optimvar('S',Nt,sum(BatteriPlace),'LowerBound',Sl,'UpperBound',Su);
% Ip2p=optimvar('Ip2p',Nt,Nh,Nh-1,'LowerBound',0);
% Xp2p=optimvar('Xp2p',Nt,Nh,Nh-1,'LowerBound',0);
%%
EVD=optimvar('EVD',Nt,N_EV,'LowerBound',0,'UpperBound',EVbeta*EVavailability);
EVC=optimvar('EVC',Nt,N_EV,'LowerBound',0,'UpperBound',EValpha*EVavailability);
EVS=optimvar('EVS',Nt,N_EV,'LowerBound',EVavailability*EVcap*0.2,'UpperBound',EVcap);

%% Objective function
linprob = optimproblem('Objective',(Pg'+En_price)*sum(G,2)-Pg'*sum(N,2)*Marginal_LR);
% linprob = optimproblem('Objective',Pg'*(sum(G,2)));
%% Constraints
% linprob.Constraints.SOC = S(1,:)==S0+eta_ch*C(1,:)-(1/eta_dis)*D(1,:);
% for i=2:Nt
% linprob.Constraints.SOC = [linprob.Constraints.SOC; S(i,:)==S(i-1,:)+eta_ch*C(i,:)-(1/eta_dis)*D(i,:)];
% end

linprob.Constraints.EVSOC=[];

for j=1:N_EV
    linprob.Constraints.EVSOC=[linprob.Constraints.EVSOC, EVS(ats(j),j)==arrivalSoC(j)+eta_ch*EVC(ats(j),j)-(1/eta_dis)*EVD(ats(j),j)];
end
for j=1:N_EV
    for i=ats(j)+1:Nt
        linprob.Constraints.EVSOC=[linprob.Constraints.EVSOC, EVS(i,j)==EVS(i-1,j)+eta_ch*EVC(i,j)-(1/eta_dis)*EVD(i,j)];
    end
    
    
    linprob.Constraints.EVSOC=[linprob.Constraints.EVSOC, EVS(1,j)==arrivalSoC(j)+eta_ch*EVC(1,j)-(1/eta_dis)*EVD(1,j)];
    for i=2:dts(j)
        linprob.Constraints.EVSOC=[linprob.Constraints.EVSOC, EVS(i,j)==EVS(i-1,j)+eta_ch*EVC(i,j)-(1/eta_dis)*EVD(i,j)];
    end
    linprob.Constraints.EVSOC=[linprob.Constraints.EVSOC, EVS(Nt,j)==arrivalSoC(j)];
end


%         linprob.Constraints.EVSOC1=[linprob.Constraints.EVSOC1, EVS(1,j)==arrivalSoC(j)+eta_ch*EVC(1,j)-(1/eta_dis)*EVD(1,j)];
%         for i=1+1:dts(j)
%             linprob.Constraints.EVSOC=[linprob.Constraints.EVSOC, EVS(i,j)==EVS(i-1,j)+eta_ch*EVC(i,j)-(1/eta_dis)*EVD(i,j)];
%         end
%         for i=ats(j)+1:48
%             linprob.Constraints.EVSOC=[linprob.Constraints.EVSOC, EVS(i,j)==EVS(i-1,j)+eta_ch*EVC(i,j)-(1/eta_dis)*EVD(i,j)];
%         end
        

linprob.Constraints.EVSOCF=[];
for j=1:N_EV
    linprob.Constraints.EVSOCF=[linprob.Constraints.EVSOCF, EVS(dts(j),j)==DepartureSoC(j)];
end


% for i=1:Nh
%     for j=1:Nt
%     I(j,i)=sum(Ip2p(j,i,:));
%     X(j,i)=sum(Xp2p(j,i,:));
%     end
% end

linprob.Constraints.eq1 = [];

kk=0;
for i=1:Nh
    if EVPlace(i)==1
        kk=kk+1;
        linprob.Constraints.eq1=[linprob.Constraints.eq1,res(:,i)+G(:,i)+EVD(:,kk)==dem(:,i)+EVC(:,kk)+N(:,i)];
    else
        linprob.Constraints.eq1=[linprob.Constraints.eq1,res(:,i)+G(:,i)==dem(:,i)+N(:,i)];
    end
end

% IXpind=zeros(Nh-1,Nh);
% for i=1:length(IXpind(1,:))
%     for j=1:length(IXpind(:,1))
%         if i<=j
%             IXpind(j,i)=j+1;
%         else
%             IXpind(j,i)=j;
%         end
%     end
% end

% linprob.Constraints.eq3 = [];
% for i=1:Nh
%     for j=1:Nh-1
%         in=IXpind(j,i);
%         jn=IXpind(:,in)==i;
%         linprob.Constraints.eq3 = [linprob.Constraints.eq3; Ip2p(:,i,j)==psip2p*Xp2p(:,in,jn)];
%     end
% end
% 
% linprob.Constraints.eq5 = psip2p*sum(X,2)==sum(I,2);
%% Evaluation
[linsol,fval] = solve(linprob);
end