%% Meta 4
% Luis Filipe Lopes Henriques
% 2021226162

clear all; close all; clc;

%% 21. Carregar a estrutura da meta anterior
fprintf("Carregando estrutura de dados da Meta 3...\n");
load('meta2_audiodata.mat');  % ou meta3_audiodata.mat se existir

if ~exist('audioData', 'var')
    error('Estrutura audioData não encontrada!');
end

fprintf("Estrutura carregada com %d registos.\n", length(audioData));

%% 22. Calcular a STFT (spectrogram) com várias parametrizações por dígito
fprintf("Calculando STFT para cada dígito...\n");

janela = 512;
overlap = 256;
nfft = 2048;

digitos = 0:9;
exemplos = [];

for d = digitos
    idx = find([audioData.digito] == d, 1);
    if ~isempty(idx)
        exemplos = [exemplos, idx];
    end
end

figure('Name', 'STFT - Um exemplo por dígito', 'Position', [100, 100, 1400, 800]);

for i = 1:length(exemplos)
    idx = exemplos(i);
    sinal = audioData(idx).sinal_processado;
    fs = audioData(idx).fs;

    subplot(5, 2, i);
    spectrogram(sinal, janela, overlap, nfft, fs, 'yaxis');
    title(sprintf('Dígito %d', audioData(idx).digito));
    ylim([0 8]);  % Opcional para melhor visualização
end


fprintf("STFT concluída.\n");

%% 23. Extrair 5 características tempo-frequência melhores
fprintf("Extraindo características tempo-frequência (versão melhorada)...\n");

for i = 1:length(audioData)
    s = audioData(i).sinal_processado;
    fs = audioData(i).fs;

    % STFT com parâmetros definidos
    janela = 512;
    overlap = 256;
    nfft = 2048;

    [S,F,T,P] = spectrogram(s, janela, overlap, nfft, fs);

    % Frequência máxima considerada (ignorar ruído muito agudo)
    Fmax = 4000;
    idxFreq = F <= Fmax;

    % Limitar o espectrograma
    P = P(idxFreq, :);
    F = F(idxFreq);

    % Matriz de potência log
    logP = 10 * log10(P + eps);

    % === NOVAS FEATURES ===

    % 1. Frequência com pico de potência global
    [~, idxMax] = max(P(:));
    [fIdx, tIdx] = ind2sub(size(P), idxMax);
    freq_pico_global = F(fIdx);
    tempo_pico_global = T(tIdx);

    

    
    % 2. Tempo com maior energia total
    energia_tempo = sum(P, 1);
    [~, idxTempoMax] = max(energia_tempo);
    tempo_max_energia = T(idxTempoMax);

    % 3. Número de janelas (tempo) com energia total acima de limiar
    limiar = 0.05 * max(energia_tempo);
    tempo_ativo = sum(energia_tempo > limiar);

    % 4. Banda de frequência com maior concentração de energia
    bandas = [0 500; 500 1000; 1000 2000; 2000 4000];
    energia_bandas = zeros(1, size(bandas,1));
    for b = 1:size(bandas,1)
        idxB = (F >= bandas(b,1)) & (F < bandas(b,2));
        energia_bandas(b) = sum(P(idxB, :), 'all');
    end
    [~, banda_max] = max(energia_bandas);

    % 5. Entropia espectral (distribuição da energia em F)
    energia_por_f = sum(P, 2);
    prob = energia_por_f / sum(energia_por_f + eps);
    entropia = -sum(prob .* log2(prob + eps));

    % Guardar
    audioData(i).features_stft.freq_pico_global = freq_pico_global;
    audioData(i).features_stft.tempo_pico_global = tempo_pico_global;
    audioData(i).features_stft.tempo_ativo = tempo_ativo;
    audioData(i).features_stft.tempo_max_energia = tempo_max_energia;
    audioData(i).features_stft.banda_max = banda_max;
    audioData(i).features_stft.entropia_espectral = entropia;

    % Energia total da STFT
    audioData(i).features_stft.energia_total = sum(P(:));
end

fprintf("Características melhoradas extraídas.\n");


%% 24. Visualização das 3 melhores características

fprintf("Visualizando correlações das novas features...\n");

digitos = [audioData.digito]';
f_pico = arrayfun(@(x) x.features_stft.freq_pico_global, audioData)';
t_pico = arrayfun(@(x) x.features_stft.tempo_pico_global, audioData)';
t_max = arrayfun(@(x) x.features_stft.tempo_max_energia, audioData)';
banda = arrayfun(@(x) x.features_stft.banda_max, audioData)';
entro = arrayfun(@(x) x.features_stft.entropia_espectral, audioData)';
t_ativo = arrayfun(@(x) x.features_stft.tempo_ativo, audioData)';

figure('Name', 'Correlação - Características Tempo-Frequência Relevantes', 'Position', [100, 100, 1200, 800]);



subplot(2,2,1);
scatter(f_pico, t_ativo, 15, digitos, 'filled');
title('Freq. Pico vs. Tempo Ativo');
xlabel('Freq. Pico Global (Hz)'); ylabel('Nº de Janelas Ativas');
colorbar('Ticks', 0:9); grid on;

subplot(2,2,3);
scatter3(t_ativo, banda, entro, 30, digitos, 'filled');
title('Tempo Ativo vs. Banda vs. Entropia');
xlabel('Janelas Ativas'); ylabel('Banda com Máx Energia'); zlabel('Entropia');
colorbar('Ticks', 0:9); grid on; view(30,30);


subplot(2,2,2);
scatter(t_pico, t_max, 15, digitos, 'filled');
title('Tempo Pico vs. Tempo Máx. Energia');
xlabel('Tempo Pico Global (s)'); ylabel('Tempo Max Energia (s)');
colorbar('Ticks', 0:9); grid on;


subplot(2,2,4);
scatter3(f_pico, banda, entro, 30, digitos, 'filled');
title('Freq. Pico vs. Banda vs. Entropia');
xlabel('Freq. Pico'); ylabel('Banda'); zlabel('Entropia');
colorbar('Ticks', 0:9); grid on; view(30,30);

%mfcc try it

%% 25. DWT - Transformada Wavelet Discreta
fprintf("Aplicando DWT e extraindo energia dos coeficientes...\n");

for i = 1:length(audioData)
    s = audioData(i).sinal_processado;
    
    % Aplicar DWT nível 4 com wavelet 'db4'
    [C,L] = wavedec(s, 4, 'db4');

    % Extrair coeficientes de aproximação e detalhe
    A4 = appcoef(C, L, 'db4');
    D4 = detcoef(C, L, 4);
    D3 = detcoef(C, L, 3);
    D2 = detcoef(C, L, 2);
    D1 = detcoef(C, L, 1);

    % Energia dos coeficientes
    energiaDWT = [sum(A4.^2), sum(D4.^2), sum(D3.^2), sum(D2.^2), sum(D1.^2)];

    audioData(i).features_dwt.energia_coef = energiaDWT;
end

fprintf("DWT concluída.\n");

%% Comparação visual STFT vs DWT
energiaSTFT_all = arrayfun(@(x) x.features_stft.energia_total, audioData)';
energiaDWT_all = arrayfun(@(x) sum(x.features_dwt.energia_coef), audioData)';


figure('Name', 'Comparação STFT vs DWT');
scatter(energiaSTFT_all, energiaDWT_all, 20, digitos, 'filled');
xlabel("Energia STFT"); ylabel("Energia DWT");
title("Comparação entre Energia Total da STFT e DWT");
colorbar('Ticks', 0:9); grid on;

%% 26. Guardar estrutura
fprintf("Guardando estrutura final...\n");

save('meta4_audiodata.mat', 'audioData');
fprintf("Meta 4 concluída com sucesso!\n");
