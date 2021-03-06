function test_ft_appendfreq

% TEST test_ft_appendfreq
% TEST ft_appendfreq

% make some dummy frequency structures
freq1.label = {'1';'2'};
freq1.freq  = 1:10;
freq1.time  = 1:5;
freq1.dimord = 'chan_freq_time';
freq1.powspctrm = randn(2,10,5);

cfg = [];
cfg.parameter = 'powspctrm';

freq2         = freq1;
cfg.appenddim = 'rpt';
freqrpt       = ft_appendfreq(cfg, freq1, freq2);
cfg.appenddim = 'auto';
freqrptauto   = ft_appendfreq(cfg, freq1, freq2);

freq2         = freq1;
freq2.label   = {'3';'4'};
cfg.appenddim = 'chan';
freqchan      = ft_appendfreq(cfg, freq1, freq2);
cfg.appenddim = 'auto';
freqchanauto  = ft_appendfreq(cfg, freq1, freq2);

freq2         = freq1;
freq2.freq    = 11:20;
cfg.appenddim = 'freq';
freqfreq      = ft_appendfreq(cfg, freq1, freq2);
cfg.appenddim = 'auto';
freqfreqauto  = ft_appendfreq(cfg, freq1, freq2);

freq2         = freq1;
freq2.time    = 6:10;
cfg.appenddim = 'time';
freqtime      = ft_appendfreq(cfg, freq1, freq2);
cfg.appenddim = 'auto';
freqtimeauto  = ft_appendfreq(cfg, freq1, freq2);

% now test for numerical inaccurracies, should concatenate across 'rpt'
freq2          = freq1;
freq2.time     = freq1.time+0.0000001;
cfg.appenddim  = 'auto';
freqrpt2       = ft_appendfreq(cfg, freq1, freq2);
 

