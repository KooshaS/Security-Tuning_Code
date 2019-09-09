%%%%%%%%%% Square Integration Domain with K = 2 Components %%%%%%%%%%
clc, clear all


%%% Data Prepration %%%
load 'Dataset1.mat'

signal = zeros(106, 19200);
for i= 1:106
    % Channel F_PZ Data
%     x = Physionet_EEG_MI(i,23,:);
    x = Raw_Data(i,2,:);
    signal(i,:) = reshape (x, [1, 19200]);
end

%%% Feature Extraction %%%
feature = zeros(2, 5, 239);
for i= 1:2
    for j = 1:239     
        signal_freq = abs(fft(signal(i, (j - 1)*80 + 1:(j - 1)*80 + 160)));
        signal_freq = signal_freq(2:160/2+1);                    
        feature(i, 1, j) = mean(signal_freq(1:3));
        feature(i, 2, j) = mean(signal_freq(4:7));
        feature(i, 3, j) = mean(signal_freq(8:13));      
        feature(i, 4, j) = mean(signal_freq(14:30));
        feature(i, 5, j) = mean(signal_freq(31:40));
    end   
end

%%% Training Phase %%%%
[muhat_sub1_trn1,sigmahat_sub1_trn1] = normfit(reshape(feature(1, 1, 1:180), [1, 180]));
[muhat_sub1_trn2,sigmahat_sub1_trn2] = normfit(reshape(feature(1, 2, 1:180), [1, 180]));
[muhat_sub1_trn3,sigmahat_sub1_trn3] = normfit(reshape(feature(1, 3, 1:180), [1, 180]));
[muhat_sub1_trn4,sigmahat_sub1_trn4] = normfit(reshape(feature(1, 4, 1:180), [1, 180]));
[muhat_sub1_trn5,sigmahat_sub1_trn5] = normfit(reshape(feature(1, 5, 1:180), [1, 180]));

[muhat_sub2_trn1,sigmahat_sub2_trn1] = normfit(reshape(feature(2, 1, 1:180), [1, 180]));
[muhat_sub2_trn2,sigmahat_sub2_trn2] = normfit(reshape(feature(2, 2, 1:180), [1, 180]));
[muhat_sub2_trn3,sigmahat_sub2_trn3] = normfit(reshape(feature(2, 3, 1:180), [1, 180]));
[muhat_sub2_trn4,sigmahat_sub2_trn4] = normfit(reshape(feature(2, 4, 1:180), [1, 180]));
[muhat_sub2_trn5,sigmahat_sub2_trn5] = normfit(reshape(feature(2, 5, 1:180), [1, 180]));

%%% System Class %%%
[muhat_w_1,sigmahat_w_1] = normfit([reshape(feature(1, 1, 1:180), [1, 180]) reshape(feature(2, 1, 1:180), [1, 180])]);
[muhat_w_2,sigmahat_w_2] = normfit([reshape(feature(1, 2, 1:180), [1, 180]) reshape(feature(2, 2, 1:180), [1, 180])]);
[muhat_w_3,sigmahat_w_3] = normfit([reshape(feature(1, 3, 1:180), [1, 180]) reshape(feature(2, 3, 1:180), [1, 180])]);
[muhat_w_4,sigmahat_w_4] = normfit([reshape(feature(1, 4, 1:180), [1, 180]) reshape(feature(2, 4, 1:180), [1, 180])]);
[muhat_w_5,sigmahat_w_5] = normfit([reshape(feature(1, 5, 1:180), [1, 180]) reshape(feature(2, 5, 1:180), [1, 180])]);

%%% Testing Phase %%%
options = statset('Display','final');
GMModel_sub1_tst = fitgmdist(reshape(feature(1, :, 181:239), [5, 59])',2,'Options',options);
% hold on
% h = ezcontour(gmPDF,[0 1000],[0 600]);
% title('Scatter Plot and PDF Contour')
% hold off

GMModel_sub2_tst = fitgmdist(reshape(feature(2, :, 181:239), [5, 59])',2,'Options',options);
% hold on
% h = ezcontour(gmPDF,[0 1000],[0 600]);
% title('Scatter Plot and PDF Contour')
% hold off

%%% CDFs %%%
thr = 0;
changing_seed = 1000;
FAR = zeros(1, changing_seed);
security_bits = zeros(1, changing_seed);
for i = 1:changing_seed
    thr = thr + 3*max([sigmahat_sub1_trn1 sigmahat_sub1_trn2 sigmahat_sub1_trn3 sigmahat_sub1_trn4 sigmahat_sub1_trn5])/changing_seed;

    mu1 = [GMModel_sub2_tst.mu(1,1) GMModel_sub2_tst.mu(1,2) GMModel_sub2_tst.mu(1,3) GMModel_sub2_tst.mu(1,4) GMModel_sub2_tst.mu(1,5)];
    Sigma1 = reshape(GMModel_sub2_tst.Sigma(:,:,1), [5, 5]);
    [F1,err1] = mvncdf([muhat_sub1_trn1 - thr muhat_sub1_trn2 - thr muhat_sub1_trn3 - thr muhat_sub1_trn4 - thr muhat_sub1_trn5 - thr],...
                       [muhat_sub1_trn1 + thr muhat_sub1_trn2 + thr muhat_sub1_trn3 + thr muhat_sub1_trn4 + thr muhat_sub1_trn5 + thr],mu1,Sigma1);
    
    mu2 = [GMModel_sub2_tst.mu(2,1) GMModel_sub2_tst.mu(2,2) GMModel_sub2_tst.mu(2,3) GMModel_sub2_tst.mu(2,4) GMModel_sub2_tst.mu(2,5)];
    Sigma2 = reshape(GMModel_sub2_tst.Sigma(:,:,2), [5, 5]);
    [F2,err2] = mvncdf([muhat_sub1_trn1 - thr muhat_sub1_trn2 - thr muhat_sub1_trn3 - thr muhat_sub1_trn4 - thr muhat_sub1_trn5 - thr],...
                       [muhat_sub1_trn1 + thr muhat_sub1_trn2 + thr muhat_sub1_trn3 + thr muhat_sub1_trn4 + thr muhat_sub1_trn5 + thr],mu2,Sigma2);
    
    FAR(1, i) = 100*(GMModel_sub2_tst.ComponentProportion(1)*F1 + GMModel_sub2_tst.ComponentProportion(2)*F2);

    security_bits(1, i) = log2(10*sigmahat_w_1*10*sigmahat_w_2*10*sigmahat_w_3*10*sigmahat_w_4*10*sigmahat_w_5/(thr^5));
end

thr = 0;
changing_seed = 1000;
FRR = zeros(1, changing_seed);
for i = 1:changing_seed
    thr = thr + 3*max([sigmahat_sub1_trn1 sigmahat_sub1_trn2 sigmahat_sub1_trn3 sigmahat_sub1_trn4 sigmahat_sub1_trn5])/changing_seed;
    
    mu1 = [GMModel_sub1_tst.mu(1,1) GMModel_sub1_tst.mu(1,2) GMModel_sub1_tst.mu(1,3) GMModel_sub1_tst.mu(1,4) GMModel_sub1_tst.mu(1,5)];
    Sigma1 = reshape(GMModel_sub1_tst.Sigma(:,:,1), [5, 5]);
    [F1,err1] = mvncdf([muhat_sub1_trn1 - thr muhat_sub1_trn2 - thr muhat_sub1_trn3 - thr muhat_sub1_trn4 - thr muhat_sub1_trn5 - thr],...
                       [muhat_sub1_trn1 + thr muhat_sub1_trn2 + thr muhat_sub1_trn3 + thr muhat_sub1_trn4 + thr muhat_sub1_trn5 + thr],mu1,Sigma1);
    
    mu2 = [GMModel_sub1_tst.mu(2,1) GMModel_sub1_tst.mu(2,2) GMModel_sub1_tst.mu(2,3) GMModel_sub1_tst.mu(2,4) GMModel_sub1_tst.mu(2,5)];
    Sigma2 = reshape(GMModel_sub1_tst.Sigma(:,:,2), [5, 5]);
    [F2,err2] = mvncdf([muhat_sub1_trn1 - thr muhat_sub1_trn2 - thr muhat_sub1_trn3 - thr muhat_sub1_trn4 - thr muhat_sub1_trn5 - thr],...
                       [muhat_sub1_trn1 + thr muhat_sub1_trn2 + thr muhat_sub1_trn3 + thr muhat_sub1_trn4 + thr muhat_sub1_trn5 + thr],mu2,Sigma2);
    
    FRR(1, i) = 100*(1 - GMModel_sub1_tst.ComponentProportion(1)*F1 - GMModel_sub1_tst.ComponentProportion(2)*F2);    
end

HTER = (FAR + FRR)/2;

figure
yyaxis left
% t1 = 1:1000;
% t2 = 1:20:1000;
% vq2 = interp1(t1,HTER,t2,'spline');
t3 = 0.003:0.003:3;
% plot(t2,vq2);
% plot(t3,vq2);
plot(t3,HTER);

% plot(HTER)
xlabel('Threshold');
ylabel('HTER(%)');

yyaxis right
t4 = 0.003:0.003:3;
plot(t4,security_bits)
ylabel('Security Strength (bits)');







