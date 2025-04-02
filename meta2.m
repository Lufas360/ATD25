% Load the data structure from meta1_audiodata.mat
data = load('meta1_audiodata.mat');
% Extract the relevant fields
audioData = data.audioData;

% Extract the fields into separate variables
energia_total = [audioData.features_temporais].energia_total;
energia_partes = {audioData.features_temporais}.energia_partes;
amp_max = [audioData.features_temporais].amp_max;
zcr = [audioData.features_temporais].zcr;
amp_std = [audioData.features_temporais].amp_std;
razao_energia = [audioData.features_temporais].razao_energia;
duracao_efetiva = [audioData.features_temporais].duracao_efetiva;