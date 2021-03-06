function [spike] = ft_spike_maketrials(cfg,spike)

% FT_SPIKE_MAKETRIALS converts raw timestamps in a SPIKE structure to spike
% times that are relative to an event trigger in an SPIKE structure. This
% is a preprocessing step to use functions such as FT_SPIKE_PSTH.
%
% The main function of FT_SPIKE_MAKETRIALS is to create the field
% spike.time and spike.trial, which contain the trial numbers in which the
% spikes were recorded, and the onset and offset of the trial relative to
% trigger time t = 0.
%
% Use as
%   [spike] = ft_spike_maketrials(cfg,spike)
%
% Inputs:
%     spike: The raw spike datatype, obtained from FT_READ_SPIKE
%
% Configurations:
%
%   cfg.trl  = is an nTrials-by-M matrix, with at least 3 columns:
%     Every row contains start (col 1), end (col 2) and offset of the event
%     trigger in the trial in timestamp or sample units (cfg.trlunit). 
%     For example, an offset of -1000 means that the trigger (t = 0 sec) 
%     occurred 1000 timestamps or samples after the
%     trial start.
%     If more columns are added than 3, these are used to construct the
%     spike.trialinfo field having information about the trial.
%
%   cfg.trlunit = 'timestamps' (default) or 'samples'. 
%     If 'samples', cfg.trl should 
%     be specified in samples, and cfg.hdr = data.hdr should be specified.
%     This option can be used to reuse a cfg.trl that was used for
%     preprocessing LFP data. 
%     If 'timestamps', cfg.timestampspersecond should be
%     specified, but cfg.hdr should not.
%
%   cfg.hdr     = struct, should be specified if cfg.trlunit = 'samples'.
%     This should be specified as cfg.hdr = data.hdr where data.hdr
%     contains the subfields data.hdr.Fs (sampling frequency of the LFP),
%     data.hdr.FirstTimeStamp, and data.hdr.TimeStampPerSecond.
%
%   cfg.timestampspersecond = number of timestaps per second (for
%     Neuralynx, 1000000 for example). This can be computed for example from
%     the LFP hdr (cfg.timestampspersecond = data.hdr.Fs*data.hdr.TimeStampPerSecond)
%     or is a priori known.
%
% Outputs appended to spike:
%   spike.time                  = 1-by-nUnits cell array, containing the spike times in
%                                 seconds relative to the event trigger.
%   spike.trial                 = 1-by-nUnits cell array, containing the trial number for
%                                 every spike telling in which trial it was recorded.
%   spike.trialtime             = nTrials-by-2 matrix specifying the start and end of
%                                 every trial in seconds.
%   spike.trialinfo             = contains trial information

% Copyright (C) 2010-2013, Martin Vinck
%
% $Id$

revision = '$Id$';

% do the general setup of the function
ft_defaults
ft_preamble help
ft_preamble callinfo
ft_preamble trackconfig

% check if input data is indeed spikeraw format
spike   = ft_checkdata(spike,'datatype', 'spike', 'feedback', 'yes');
nUnits  = length(spike.label);

% process the trlunit field
cfg.trlunit = ft_getopt(cfg,'trlunit','timestamps');
cfg = ft_checkopt(cfg,'trlunit', 'char', {'timestamps', 'samples'});

% process the trl field, which is required
cfg = ft_checkconfig(cfg, 'required', {'trl'});
cfg = ft_checkopt(cfg,'trl', {'numericvector', 'numericmatrix'});
if size(cfg.trl,2)<3,
  error('cfg.trl should contain at least 3 columns, 1st column start of trial, 2nd column end, 3rd offset, in timestamp or sample units')
end
cfg.trl = double(cfg.trl);
events  = cfg.trl(:,1:2)'; %2-by-nTrials now
if ~issorted(events(:)), warning('your trials are overlapping, trials will not be statistically independent'); end
if ~issorted(events,'rows'), error('the trials are not in sorted order'); end

% check if the inputs are congruent: hdr should not be there if unit is timestamps
if strcmp(cfg.trlunit,'timestamps')
  cfg = ft_checkconfig(cfg,'forbidden', 'hdr');
  cfg = ft_checkconfig(cfg, 'required', {'timestampspersecond'});  
else
  cfg = ft_checkconfig(cfg, 'required', {'hdr'});      
  if ~isfield(cfg.hdr, 'FirstTimeStamp'), error('cfg.hdr.FirstTimeStamp must be specified'); end
  if ~isfield(cfg.hdr, 'TimeStampPerSample'), error('cfg.hdr.TimeStampPerSample must be specified'); end
  if ~isfield(cfg.hdr, 'Fs'), error('cfg.hdr.Fs, the sampling frequency of the LFP must be specified'); end
end
  
%cfg = ft_checkconfig(cfg, 'allowed', {'trlunit', 'timestampspersecond', 'hdr', 'trl'});

if strcmp(cfg.trlunit,'timestamps')
  
  % make a loop through the spike units and make the necessary conversions
  nTrials = size(cfg.trl,1);
  for iUnit = 1:nUnits
    ts = double(spike.timestamp{iUnit}(:));

    % take care of the waveform information as well
    hasWave =  isfield(spike, 'waveform') && ~isempty(spike.waveform) && ~isempty(spike.waveform{iUnit});
      
    % make the timestamps relative to the trigger
    trialNum = [];
    sel       = [];
    for iTrial = 1:nTrials
      isVld = find(ts>=events(1,iTrial) &ts<=events(2,iTrial));
      if ~isempty(isVld)
        trialNum = [trialNum; iTrial*ones(length(isVld),1)];
      end
      sel   = [sel; isVld(:)];
    end

    % subtract the event (t=0) from the timestamps directly
    if ~isempty(trialNum)
      ts = ts(sel);
      dt = ts - cfg.trl(trialNum,1); % error if empty
      dt = dt/cfg.timestampspersecond + cfg.trl(trialNum,3)/cfg.timestampspersecond;
    else
      dt = [];
    end
    trialDur = (cfg.trl(:,2)-cfg.trl(:,1))/cfg.timestampspersecond;
    time = [cfg.trl(:,3)/cfg.timestampspersecond (cfg.trl(:,3)/cfg.timestampspersecond + trialDur)]; % make the time-axis

    % gather the results
    spike.time{iUnit}   = dt(:)';
    spike.trial{iUnit}  = trialNum(:)';
    spike.trialtime     = time;
    if hasWave, spike.waveform{iUnit} = spike.waveform{iUnit}(:,:,sel); end
    try spike.unit{iUnit} = spike.unit{iUnit}(sel); end      
    try spike.fourierspctrm{iUnit} = spike.fourierspctrm{iUnit}(sel,:,:); end
    ts = spike.timestamp{iUnit}(sel);
    spike.timestamp{iUnit} = ts(:)';
  end

elseif strcmp(cfg.trlunit,'samples')
   
  nTrials            = size(cfg.trl,1);    
  FirstTimeStamp     = double(cfg.hdr.FirstTimeStamp);
  TimeStampPerSample = double(cfg.hdr.TimeStampPerSample);
  Fs                 = double(cfg.hdr.Fs);
      
  [spike.time,spike.trial] = deal(cell(1,nUnits));
  spike.trialtime = zeros(nTrials,2);
  for iUnit = 1:nUnits
    
    % determine the corresponding sample numbers for each timestamp
    ts = double(spike.timestamp{iUnit}(:));
    sample = (ts-FirstTimeStamp)/TimeStampPerSample + 1; % no rounding (compare ft_appendspike)
    waveSel = [];
    for iTrial = 1:nTrials
      begsample = cfg.trl(iTrial,1);
      endsample = cfg.trl(iTrial,2);
      sel       = find((sample>=begsample) & (sample<=endsample));
      dSample   = sample(sel)-begsample;
      offset    = cfg.trl(iTrial,3)/Fs;               
      tTrial    = dSample/Fs + offset;
      trialNum  = ones(1,length(tTrial))*iTrial;
      trialDur  = (cfg.trl(iTrial,2)-cfg.trl(iTrial,1))/Fs;
      
      spike.time{iUnit}         = [spike.time{iUnit} tTrial(:)'];
      spike.trial{iUnit}        = [spike.trial{iUnit} trialNum];
      if iUnit==1, 
        spike.trialtime(iTrial,:) = [offset offset+trialDur]; 
      end
      waveSel  = [waveSel; sel(:)];
    end     
    
    % select the other fields
    try, spike.waveform{iUnit}      = spike.waveform{iUnit}(:,:,waveSel);      end
    spike.timestamp{iUnit}          = spike.timestamp{iUnit}(waveSel);
    try, spike.unit{iUnit}          = spike.unit{iUnit}(waveSel);              end
    try, spike.fourierspctrm{iUnit} = spike.fourierspctrm{iUnit}(waveSel,:,:); end
  end 
end

if size(cfg.trl,2) > 3
    spike.trialinfo        = cfg.trl(:,4:end);
end

% do the general cleanup and bookkeeping at the end of the function
ft_postamble trackconfig
ft_postamble callinfo
ft_postamble previous spike
ft_postamble history spike

