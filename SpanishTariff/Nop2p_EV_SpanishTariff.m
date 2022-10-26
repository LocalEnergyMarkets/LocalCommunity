function [linsol,fval]=Nop2p_EV_SpanishTariff(dem,Pe,Pf,Nt,res,psip2p,ET3,PowerCost,TimeStepperHour, ATS, DTS, Nev, Cap_perEV, CHrate,DCHrate,arrSoC,DepSoC)

Nh=length(dem(1,:));
%% defining variables
%% EV fleet
ats=ATS;  %*TimeStepperHour+1;
dts=DTS;   %*TimeStepperHour-1;
EVS=optimvar('EVS',dts-ats+1,1,'LowerBound',0,'UpperBound',Nev*Cap_perEV);
EVD=optimvar('EVD',dts-ats+1,1,'LowerBound',0,'UpperBound',Nev*DCHrate);
EVC=optimvar('EVC',dts-ats+1,1,'LowerBound',0,'UpperBound',Nev*CHrate);

aa=size(dem);
G=optimvar('G',aa(1),aa(2),'LowerBound',0);
%D=optimvar('D',Nt,sum(BatteryPlace),'LowerBound',0,'UpperBound',beta);
%C=optimvar('C',Nt,sum(BatteryPlace),'LowerBound',0,'UpperBound',alpha);
%S=optimvar('S',Nt,sum(BatteryPlace),'LowerBound',Sl,'UpperBound',Su);
% % Ip2p=optimvar('Ip2p',Nt,Nh,Nh-1,'LowerBound',0);
% % Xp2p=optimvar('Xp2p',Nt,Nh,Nh-1,'LowerBound',0);
Peak=optimvar('Peak',6,1,'LowerBound',0);     % 6 is the number of periods
%% Objective function
linprob = optimproblem('Objective',Pe'*(sum(G,2)) + Pf(ats:dts)'*EVD + TimeStepperHour*PowerCost'*Peak);
%% Constraints
% linprob.Constraints.SOC = S(1,:)==S0+eta_ch*C(1,:)-(1/eta_dis)*D(1,:);
% for i=2:Nt
% linprob.Constraints.SOC = [linprob.Constraints.SOC; S(i,:)==S(i-1,:)+eta_ch*C(i,:)-(1/eta_dis)*D(i,:)];
% end


arrSoC=arrSoC*Nev*Cap_perEV;
DepSoC=DepSoC*Nev*Cap_perEV;

linprob.Constraints.EVSOC = EVS(1,:)==arrSoC+0.98*EVC(1,:)-(1/0.98)*EVD(1,:);
for i=2:dts-ats+1
    linprob.Constraints.EVSOC = [linprob.Constraints.EVSOC; EVS(i,:)==EVS(i-1,:)+0.98*EVC(i,:)-(1/0.98)*EVD(i,:)];
end
linprob.Constraints.FinalEVSOC = EVS(dts-ats+1,:)>=DepSoC;
% % for i=1:Nh
% %     for j=1:Nt
% %     I(j,i)=sum(Ip2p(j,i,:));
% %     X(j,i)=sum(Xp2p(j,i,:));
% %     end
% % end
linprob.Constraints.eq1EV = [];
tt=0;
for t=1:Nt
    if t<ats || t>dts
        linprob.Constraints.eq1EV=[linprob.Constraints.eq1EV,res(t,aa(2))+G(t,aa(2))>=dem(t,aa(2))];
    elseif t>=ats && t<=dts
        tt=tt+1;
        linprob.Constraints.eq1EV=[linprob.Constraints.eq1EV,res(t,aa(2))+G(t,aa(2))+EVD(tt,1)>=dem(t,aa(2))+EVC(tt,1)];
    %else
    %    linprob.Constraints.eq1EV=[linprob.Constraints.eq1EV,res(t,aa(2))+G(t,aa(2))+I(t,aa(2))>=dem(t,aa(2))+X(t,aa(2))];
    end
end


%%
linprob.Constraints.eq1 = [];
% k=0;
% for i=1:Nh
%     if BatteryPlace(i)==1
%         k=k+1;
%         linprob.Constraints.eq1=[linprob.Constraints.eq1,res(:,i)+G(:,i)+I(:,i)+D(:,k)>=dem(:,i)+X(:,i)+C(:,k)];
%     else
%         linprob.Constraints.eq1=[linprob.Constraints.eq1,res(:,i)+G(:,i)+I(:,i)>=dem(:,i)+X(:,i)];
%     end
% end
for i=1:Nh-1  % subtract the last one
    linprob.Constraints.eq1=[linprob.Constraints.eq1,res(:,i)+G(:,i)>=dem(:,i)];
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

C = unique(ET3);
if ~isempty(find(C==1, 1))
    linprob.Constraints.PeakCon1 = Peak(1) >= sum(G(ET3==1,:),2);
end
if ~isempty(find(C==2, 1))
    linprob.Constraints.PeakCon2 = Peak(2) >= sum(G(ET3==2,:),2);
end
if ~isempty(find(C==3, 1))
    linprob.Constraints.PeakCon3 = Peak(3) >= sum(G(ET3==3,:),2);
end
if ~isempty(find(C==4, 1))
    linprob.Constraints.PeakCon4 = Peak(4) >= sum(G(ET3==4,:),2);
end
if ~isempty(find(C==5, 1))
    linprob.Constraints.PeakCon5 = Peak(5) >= sum(G(ET3==5,:),2);
end
if ~isempty(find(C==6, 1))
    linprob.Constraints.PeakCon6 = Peak(6) >= sum(G(ET3==6,:),2);
end

% linprob.Constraints.eq5 = psip2p*sum(X,2)==sum(I,2);
%% Evaluation
[linsol,fval] = solve(linprob);
end