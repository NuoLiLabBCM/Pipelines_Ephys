function func_check_for_duplicate_unit_kilosort(unit1, unit1name, unit2, unit2name, single_unit_dir)

disp([unit1name, '<->', unit2name]);

figure
%%
subplot(4,4,[1 2 5 6]+8); hold on
spike_times = unit1.spike_times;
trials = unit1.trials;

spike_times_psth = {};
n_trial = 0;
for i_trial = min(trials):max(trials)
    n_trial = n_trial+1;
    spike_times_psth{n_trial,1} = spike_times(trials==i_trial)';
end
[psth t] = func_getPSTH(spike_times_psth,0,max(spike_times));
bar(t,psth,'k');hold on;
psth1 = psth(t>0 & t<5.5);
trials = trials-min(trials);
plot(spike_times,trials/max(trials)*max(psth)+max(psth)*1.2,'.k')
xlim([0 min([6 max(spike_times)])])

i_str = findstr(unit1name,'Curation');
title(['Unit',unit1name(i_str+8:end),' Ch: ',num2str(median(unit1.channel))])

subplot(4,4,3); hold on
isi = diff(spike_times);
isi = isi(find(isi<.5));
isi = [isi; -isi];
edges = [-.03:.00025:.03];
n = histc(isi,edges);
plot(edges, n, 'g')
if max(n)~=0
    axis([-.02 .02 0 max(n)]);
end
maxn=max(n);
ISI_unit1 = n;

%
subplot(4,4,[3 4 7 8]+8); hold on
spike_times = unit2.spike_times;
trials = unit2.trials;

spike_times_psth = {};
n_trial = 0;
for i_trial = min(trials):max(trials)
    n_trial = n_trial+1;
    spike_times_psth{n_trial,1} = spike_times(trials==i_trial)';
end
[psth t] = func_getPSTH(spike_times_psth,0,max(spike_times));
bar(t,psth,'k');hold on;
psth2 = psth(t>0 & t<5.5);
trials = trials-min(trials);
plot(spike_times,trials/max(trials)*max(psth)+max(psth)*1.2,'.k')
xlim([0 min([6 max(spike_times)])])

n_tmp1 = size(psth1,2);
n_tmp2 = size(psth2,2);
psth1 = psth1(1,1:min([n_tmp1 n_tmp2]));
psth2 = psth2(1,1:min([n_tmp1 n_tmp2]));

psthcorr=corr(psth1',psth2');
i_str = findstr(unit2name,'Curation');
title(['Unit',unit2name(i_str+8:end),' Ch: ',num2str(median(unit2.channel)),'psthCC=',num2str(psthcorr)])

subplot(4,4,3);hold on;
isi = diff(spike_times);
isi = isi(find(isi<.5));
isi = [isi; -isi];
edges = [-.03:.00025:.03];
n = histc(isi,edges);
plot(edges, n, 'r')
if max(n)~=0
    axis([-.02 .02 0 max([max(n) maxn])]);
end
ISI_unit2 = n;
ISICC = corr(ISI_unit1,ISI_unit2);
title(['ISICC=',num2str(ISICC)])

%CCG
spikeCC=[];
tbin=[-1:0.0005:5];
TrialCommon=intersect(unit1.stable_trials,unit2.stable_trials);
for i_trial=TrialCommon
    spiketime1=unit1.spike_times(find(unit1.trials==i_trial));
    spiketime2=unit2.spike_times(find(unit2.trials==i_trial));
    if length(spiketime1)>2&length(spiketime2)>2
        spike1=hist(spiketime1,tbin);
        spike2=hist(spiketime2,tbin);
        spike1=spike1(2:end-1);
        spike2=spike2(2:end-1);
        [spikecc,lags]=xcorr(spike1,spike2);
        spikeCC=[spikeCC;spikecc(length(spike1)-100:length(spike1)+100)];
    end
end
subplot(4,4,4);
bar([-100:100]/2,mean(spikeCC));
xlim([-20 20])
xlabel('ms');
if ~isempty(spikeCC)
    CCG_tmp = (mean(mean(spikeCC(:,find(abs([-100:100])<3))))/sum(abs([-100:100])<3))/(mean(mean(spikeCC(:,find(abs([-100:100])>=3))))/sum(abs([-100:100])>=3));
    title(['CCG ', num2str(CCG_tmp)]);
else
    CCG_tmp = 100;
end



if (psthcorr>.3 | ISICC>.3) & CCG_tmp<1
        
    %ACG
    spikeCC=[];
    for i_trial=unit1.stable_trials
        spiketime=unit1.spike_times(find(unit1.trials==i_trial));
        if length(spiketime)>2
            spike=hist(spiketime,tbin);
            spike=spike(2:end-1);
            [spikecc,lags]=xcorr(spike,spike);
            spikeCC=[spikeCC;spikecc(length(spike)-100:length(spike)+100)];
        end
    end
    spikeCC(:,101)=0;
    subplot(4,4,7);
    bar([-100:100]/2,mean(spikeCC));
    xlabel('ms');
    title('ACG_1');
    %ACG
    spikeCC=[];
    for i_trial=unit2.stable_trials
        spiketime=unit2.spike_times(find(unit2.trials==i_trial));
        if length(spiketime)>2
            spike=hist(spiketime,tbin);
            spike=spike(2:end-1);
            [spikecc,lags]=xcorr(spike,spike);
            spikeCC=[spikeCC;spikecc(length(spike)-100:length(spike)+100)];
        end
    end
    spikeCC(:,101)=0;
    subplot(4,4,8);
    bar([-100:100]/2,mean(spikeCC));
    xlabel('ms');
    title('ACG_2');
    
    % plot waveforms
    ch1=median(unit1.channel);
    subplot(4,4,[1:2]);hold on;

    % extract waveform from overlapping trials
    trial_common = intersect(unique(unit1.trials), unique(unit2.trials));

    unit1_tmp = unit1;
    unit1_tmp.spk_times_unadj = unit1_tmp.spk_times_unadj(ismember(unit1_tmp.trials,trial_common));
    unit1_tmp.spike_times = unit1_tmp.spike_times(ismember(unit1_tmp.trials,trial_common));
    unit1_tmp.trials = unit1_tmp.trials(ismember(unit1_tmp.trials,trial_common));

    unit2_tmp = unit2;
    unit2_tmp.spk_times_unadj = unit2_tmp.spk_times_unadj(ismember(unit2_tmp.trials,trial_common));
    unit2_tmp.spike_times = unit2_tmp.spike_times(ismember(unit2_tmp.trials,trial_common));
    unit2_tmp.trials = unit2_tmp.trials(ismember(unit2_tmp.trials,trial_common));

    dataFolder = single_unit_dir;
    i_str = findstr(dataFolder,'\');
    dataFolder = dataFolder(1:i_str(end-1));
    nWf = min([length(unit1_tmp.trials) length(unit2_tmp.trials) 100]);
    unit1_tmp = func_extract_waveforms(dataFolder,unit1_tmp,nWf);
    unit2_tmp = func_extract_waveforms(dataFolder,unit2_tmp,nWf);

    % plot waveform
    unit1_ch = unit1.selected_channels;
    unit2_ch = unit2.selected_channels;

    channel_all = unique([unit1_ch unit2_ch]);
    channel_all(isnan(channel_all)) = [];

    unit1_waveform = func_cat_waveforms(unit1_tmp.mean_waveform,unit1_ch,channel_all);

    unit2_waveform = func_cat_waveforms(unit2_tmp.mean_waveform,unit2_ch,channel_all);

    for k=1:5
        plot(unit1_waveform,'g');hold on;
    end
    for k=1:5
        plot(unit2_waveform,'r');hold on;
    end
    title(['Ch: ',num2str(ch1)]);
    xticks((1:length(channel_all))*82-40)
    xticklabels(string(channel_all))


    subplot(4,4,[5:6]);hold on;
    scatter(unit1.trials+unit1.spike_times,unit1.amplitudes,'g.');hold on;
    scatter(unit2.trials+unit2.spike_times,unit2.amplitudes,'r.');hold on;
 
    saveas(gcf,[single_unit_dir,'CheckDuplicate\',unit1name,unit2name,'.png'],'png');
end
close;

return







function [PSTH time] = func_getPSTH(SpikeTimes, PSTH_StartTime, PSTH_EndTime)

%
% SpikeTimes -- {n_rep,1}
%

if nargin == 1
    PSTH_StartTime = -.52;
    PSTH_EndTime = 5.020;
end

time = PSTH_StartTime:.001:PSTH_EndTime;


n_rep = size(SpikeTimes,1);
total_counts = 0;
for i_rep = 1:n_rep
    
    [counts] = hist(SpikeTimes{i_rep,1},PSTH_StartTime:0.001:PSTH_EndTime);
    total_counts = total_counts+counts/n_rep;
    
end

avg_window = ones(1,50)/0.05;
PSTH = conv(total_counts,avg_window,'same');

time = time(41:end-40);
PSTH = PSTH(41:end-40);

return



function [edges,N] = func_ISI(times)


ISI = diff(times);
ISI = ISI(find(ISI<.5));
ISI = [ISI;-ISI];
edges = [-.3:.0005:.3];
%dges = [[-.025:.0005:.025]];
N = histc(ISI,edges);

return

function unit_waveforms = func_cat_waveforms(mean_waveform,unit_ch,channel_all)

unit_waveforms = nan(1,length(channel_all)*82);
i_ch_idx = find(ismember(channel_all,unit_ch))*82;
for i_ch = 1 : length(i_ch_idx) 
    wf_idx = find(unit_ch == channel_all(i_ch_idx(i_ch)/82), 1);
    if ~isempty(wf_idx)
        wf_idx = wf_idx * 82;
        unit_waveforms((i_ch_idx(i_ch)-81):i_ch_idx(i_ch)) = mean_waveform((wf_idx-81):wf_idx);
    end
end

return