

function [StartStop] = getStartStop(data)


bins=length(data);
r=sum(data)/bins;
rows=0;
value=[];
for i=1:bins
    r1=sum(data(1:i))/i;
    t1=i;
    
    for ii=i+1:bins
        if (ii-i)>0
            r2=sum(data(i+1:ii))/(ii-i);
        end
        t2=ii-i;
        if (bins-ii)>0
            r3=sum(data(ii+1:bins))/(bins-ii);
        end
        t3=bins-ii;
        
        rows=rows+1;
        value(rows,1)=t1*(r-r1)+t2*(r2-r)+t3*(r-r3);
        value(rows,2)=i;
        value(rows,3)=ii;
    end
end


temp=value(find(value(:,1)==max(value(:,1))),:);

% if temp(2)>temp(3);
%     for i=1:bins
%         r1=sum(data(1:i))/i;
%         t1=i;
%         
%         for ii=i+1:bins
%             if (ii-i)>0
%                 r2=sum(data(i+1:ii))/(ii-i);
%             end
%             t2=ii-i;
%             if (bins-ii)>0
%                 r3=sum(data(ii+1:bins))/(bins-ii);
%             end
%             t3=bins-ii;
%             
%             rows=rows+1;
%             value(rows,1)=t1*(r-r1)+t2*(r2-r)+t3*(r-r3);
%             value(rows,2)=i;
%             value(rows,3)=ii;
%         end
%     end
% end


%temp={temp1(2),temp1(3)};
%% added on Jan 18, 2021
if length(temp(:,1))==1;
    peak=temp(2)+(temp(3)-temp(2))/2;
    spread=temp(3)-temp(2);
    StartStop=temp(2:3);
elseif length(temp(:,1))>1
    peak=mean(temp(:,2))+(mean(temp(:,3))-mean(temp(:,2)))/2;
    spread=mean(temp(:,3))-mean(temp(:,2));
    StartStop=[mean(temp(:,2)) mean(temp(:,3))];
end
    StartStop = [StartStop, peak, spread];

