%%%%%%%%%% Square Integration Domain Using MI %%%%%%%%%%
clc, clear all

tic
%%% Data Prepration %%%
load 'Dataset1.mat'

sub = 106;
signal = zeros(106, 19200);
for i= 1:106
    % Channel F_PZ Data
    x = Raw_Data(i,2,:);
    signal(i,:) = reshape (x, [1, 19200]);
end

%%% Feature Extraction %%%
feature = zeros(sub, 2, 239);
for i= 1:sub
    for j = 1:239     
        signal_freq = abs(fft(signal(i, (j - 1)*80 + 1:(j - 1)*80 + 160)));
        signal_freq = signal_freq(2:160/2+1);                    
        feature(i, 1, j) = mean(signal_freq(8:13));
        feature(i, 2, j) = mean(signal_freq(14:30));
    end   
end

%%% Training Phase %%%%
feature_trn = feature(:, :, 1:180);
[muhat_sub1_trn1,sigmahat_sub1_trn1] = normfit(reshape(permute(feature_trn(1, 1, 1:180), [2 1 3]), [1, 180]));
[muhat_sub1_trn2,sigmahat_sub1_trn2] = normfit(reshape(permute(feature_trn(1, 2, 1:180), [2 1 3]), [1, 180]));

[muhat_sub2_trn1,sigmahat_sub2_trn1] = normfit(reshape(permute(feature_trn(2:sub, 1, 1:180), [3 2 1]), [1, 180*(sub - 1)]));
[muhat_sub2_trn2,sigmahat_sub2_trn2] = normfit(reshape(permute(feature_trn(2:sub, 2, 1:180), [3 2 1]), [1, 180*(sub - 1)]));

%%% System Class %%%
[muhat_w_1,sigmahat_w_1] = normfit(reshape(permute(feature_trn(1:sub, 1, 1:180), [3 2 1]), [1, 180*sub]));
[muhat_w_2,sigmahat_w_2] = normfit(reshape(permute(feature_trn(1:sub, 2, 1:180), [3 2 1]), [1, 180*sub]));

%%% Testing Phase %%%
feature_tst = feature(:, :, 181:239);
[muhat_sub1_tst1,sigmahat_sub1_tst1] = normfit(reshape(permute(feature_tst(1, 1, :), [2 1 3]), [1, 59]));
[muhat_sub1_tst2,sigmahat_sub1_tst2] = normfit(reshape(permute(feature_tst(1, 2, :), [2 1 3]), [1, 59]));

[muhat_sub2_tst1,sigmahat_sub2_tst1] = normfit(reshape(permute(feature_tst(2:sub, 1, :), [3 2 1]), [1, 59*(sub - 1)]));
[muhat_sub2_tst2,sigmahat_sub2_tst2] = normfit(reshape(permute(feature_tst(2:sub, 2, :), [3 2 1]), [1, 59*(sub - 1)]));

%%% CDFs %%%
thr = 0;
changing_seed = 1000;
FAR = zeros(1, changing_seed);
security_bits = zeros(1, changing_seed);
for i = 1:changing_seed
    thr = thr + 10*max(sigmahat_sub1_trn1, sigmahat_sub1_trn2)/changing_seed; 
    mu = [muhat_sub2_tst1 muhat_sub2_tst2];
    Sigma = cov(reshape(permute(feature(2:sub, 1, 181:239), [3 2 1]), [59*(sub - 1), 1]), reshape(permute(feature(2:sub, 2, 181:239), [3 2 1]), [59*(sub - 1), 1]));
    [F,err] = mvncdf([muhat_sub1_trn1 - thr muhat_sub1_trn2 - thr],[muhat_sub1_trn1 + thr muhat_sub1_trn2 + thr],mu,Sigma);
    FAR(1, i) = 100*F;
%     security_bits(1, i) = log2(pi*(3*max(sigmahat_w_1, sigmahat_w_2))^2/(pi*thr^2));
security_bits(1, i) = log2((20*max(sigmahat_w_1, sigmahat_w_2))^2/((2*thr)^2));
end

thr = 0;
changing_seed = 1000;
FRR = zeros(1, changing_seed);
for i = 1:changing_seed
    thr = thr + 10*max(sigmahat_sub1_trn1, sigmahat_sub1_trn2)/changing_seed; 
    mu = [muhat_sub1_tst1 muhat_sub1_tst2];
    Sigma = cov(reshape(permute(feature(1, 1, 181:239), [2 1 3]), [59, 1]), reshape(permute(feature(1, 2, 181:239), [2 1 3]), [59, 1]));
    [F,err] = mvncdf([muhat_sub1_trn1 - thr muhat_sub1_trn2 - thr],[muhat_sub1_trn1 + thr muhat_sub1_trn2 + thr],mu,Sigma);
    FRR(1, i) = 100*(1 - F);
end

HTER = (FAR + FRR)/2;

toc
figure
yyaxis left
% t1 = 1:1000;
% t2 = 1:20:1000;
% vq2 = interp1(t1,HTER,t2,'spline');
t3 = 0.01:0.01:10;
% plot(t2,vq2);
% plot(t3,vq2);
plot(t3,HTER);

% plot(HTER)
xlabel('Threshold');
ylabel('HTER(%)');

yyaxis right
t4 = 0.01:0.01:10;
plot(t4,security_bits)
ylabel('Security Strength (bits)');







