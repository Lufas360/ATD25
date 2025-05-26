%% Meta 2
% Luis Filipe Lopes Henriques
% 2021226162

%% 10. Carregar a estrutura de dados da Meta 1
clear all; close all; clc;

% Carregar os dados da meta anterior
fprintf('Carregando dados da Meta 1...\n');
load('meta1_audiodata.mat');

% Verificar se os dados foram carregados corretamente
if ~exist('audioDataCompact', 'var')
    error('Não foi possível carregar os dados da Meta 1. Verifique se o arquivo meta1_audiodata.mat existe.');
end

% Usar a estrutura carregada
audioData = audioDataCompact;
clear audioDataCompact;

fprintf('Dados carregados com sucesso! Estrutura contém %d registos.\n', length(audioData));

% Inicializar a estrutura de features_espectrais para cada elemento
for i = 1:length(audioData)
    if ~isfield(audioData(i), 'features_espectrais')
        audioData(i).features_espectrais = struct();
    end
    
    if ~isfield(audioData(i), 'fourier')
        audioData(i).fourier = struct();
    end
end

%% 11. Calcular os coeficientes da série complexa de Fourier para cada sinal
fprintf('Calculando coeficientes da série complexa de Fourier...\n');

for i = 1:length(audioData)
    % Obter o sinal processado
    sinal = audioData(i).sinal_processado;
    fs = audioData(i).fs;
    
    % Calcular a FFT
    N = length(sinal);
    Y = fft(sinal) / N; % Normalizar pelo número de amostras
    
    % Calcular o vetor de frequências
    f = fs * (0:(N/2)) / N;
    
    % Armazenar apenas os coeficientes para frequências positivas (até fs/2)
    audioData(i).fourier.coeficientes = Y(1:floor(N/2)+1);
    audioData(i).fourier.frequencias = f;
    
    % Amplitude do espectro
    audioData(i).fourier.amplitude = abs(Y(1:floor(N/2)+1));
    
    % Fase do espectro
    audioData(i).fourier.fase = angle(Y(1:floor(N/2)+1));
    
    % Exibir progresso a cada 50 arquivos
    if mod(i, 50) == 0
        fprintf('Calculada FFT para %d/%d sinais...\n', i, length(audioData));
    end
end

fprintf('Cálculo dos coeficientes de Fourier concluído.\n');

%% 12. Calcular o espectro de amplitude mediano, primeiro e terceiro quartil para cada dígito
fprintf('Calculando estatísticas do espectro de amplitude para cada dígito...\n');

% Encontrar o comprimento máximo dos vetores de frequência
max_length = 0;
for i = 1:length(audioData)
    max_length = max(max_length, length(audioData(i).fourier.frequencias));
end

% Inicializar estrutura para armazenar estatísticas espectrais por dígito
spectralStats = struct();
for d = 0:9
    spectralStats(d+1).digito = d;
    spectralStats(d+1).frequencias = zeros(1, max_length);
    spectralStats(d+1).mediana = zeros(1, max_length);
    spectralStats(d+1).quartil25 = zeros(1, max_length);
    spectralStats(d+1).quartil75 = zeros(1, max_length);
end

% Para cada dígito, calcular estatísticas
for d = 0:9
    % Encontrar todos os sinais correspondentes ao dígito atual
    indices = find([audioData.digito] == d);
    
    if isempty(indices)
        warning('Nenhum exemplo encontrado para o dígito %d', d);
        continue;
    end
    
    % Obter o número de sinais para este dígito
    numSinais = length(indices);
    
    % Obter frequências do primeiro sinal (assumimos que são iguais para todos)
    spectralStats(d+1).frequencias = audioData(indices(1)).fourier.frequencias;
    
    % Comprimento do vetor de frequências
    numFreqs = length(spectralStats(d+1).frequencias);
    
    % Matriz para armazenar amplitudes de todos os sinais deste dígito
    allAmplitudes = zeros(numSinais, numFreqs);
    
    % Preencher a matriz de amplitudes
    for i = 1:numSinais
        idx = indices(i);
        amp = audioData(idx).fourier.amplitude;
        
        % Garantir que todos os vetores têm o mesmo comprimento
        if length(amp) < numFreqs
            amp = [amp; zeros(numFreqs - length(amp), 1)];
        elseif length(amp) > numFreqs
            amp = amp(1:numFreqs);
        end
        
        allAmplitudes(i, :) = amp;
    end
    
    % Calcular estatísticas para cada frequência
    spectralStats(d+1).mediana = median(allAmplitudes, 1);
    spectralStats(d+1).quartil25 = quantile(allAmplitudes, 0.25, 1);
    spectralStats(d+1).quartil75 = quantile(allAmplitudes, 0.75, 1);
end

% Visualizar espectros de amplitude medianos e quartis para cada dígito
figure('Name', 'Espectros de Amplitude por Dígito', 'Position', [100, 100, 1200, 800]);

for d = 0:9
    subplot(5, 2, d+1);
    
    % Limitar visualização até 8000 Hz para melhor visualização
    freqLimit = 8000;
    idx = find(spectralStats(d+1).frequencias <= freqLimit);
    
    % Plotar mediana e quartis
    hold on;
    plot(spectralStats(d+1).frequencias(idx), spectralStats(d+1).mediana(idx), 'b', 'LineWidth', 1.5);
    plot(spectralStats(d+1).frequencias(idx), spectralStats(d+1).quartil25(idx), 'r--');
    plot(spectralStats(d+1).frequencias(idx), spectralStats(d+1).quartil75(idx), 'y--');
    hold off;
    
    % Adicionar legenda
    if d == 0
        legend('Mediana', 'Q25', 'Q75');
    end
    
    % Formatação
    title(sprintf('%d', d));
    xlabel('Frequência (Hz)');
    ylabel('Amplitude');
    grid on;
    xlim([0, freqLimit]);
end

% Ajustar espaçamento dos subplots
tight = get(gcf, 'Position');
set(gcf, 'Position', tight);

% Análise de espectros de amplitude
% Para todos os digitos a informação espectral é acumulada nas frequências a baixo de 1kHz 
% que faz sentido porque é nesta parte do espectro que está a voz humana
% Uma exceção a isto são numeros com o som "S" como o 6 e o 7 que têm pequenos picos acime de 1.5kHz
% O numero 8 tambem tem um pico nos 2kHz, provavelmente devido ao som "T"
% Todos os números parecem ter o pico mais alto entre os 100Hz e 200Hz
% Diferentes números têm diferentes quantidades de picos que pode ser útil para distinguir os números


fprintf('Análise espectral por dígito concluída.\n');

%% 13. Calcular características espectrais
fprintf('Calculando características espectrais dos sinais...\n');

for i = 1:length(audioData)
    % Obter espectro de amplitude e frequências
    amplitude = audioData(i).fourier.amplitude;
    freq = audioData(i).fourier.frequencias;
    
    % 1. Posição e amplitude do primeiro pico (máximo) espectral
    [maxAmp, maxIdx] = max(amplitude);
    maxFreq = freq(maxIdx);
    
    % 2. Centroides espectrais (média ponderada das frequências pelo espectro)
    amplitude_positiva = max(amplitude, 0);  % Garantir que amplitudes sejam positivas
    soma_amplitude = sum(amplitude_positiva);
    
    if soma_amplitude > 0
        centroide = sum(freq * amplitude_positiva) / soma_amplitude;
        % fprintf('num: %d\n', i);
        % fprintf('Centroide espectral: %.2f Hz\n', centroide);
    else
        centroide = 0;
    end
    
    % 3. Spectral Edge Frequency (95% da energia espectral)
    energia_cumulativa = cumsum(amplitude.^2);
    energia_total = energia_cumulativa(end);
    if energia_total > 0
        sef95_idx = find(energia_cumulativa >= 0.95 * energia_total, 1);
        if ~isempty(sef95_idx)
            sef95 = freq(sef95_idx);
        else
            sef95 = freq(end);
        end
    else
        sef95 = 0;
    end
    
    % 4. Desvio padrão espectral
    if length(amplitude) > 1 && sum(amplitude) > 0
        spectral_std = sqrt(sum(((freq - centroide).^2) * amplitude) / sum(amplitude));
    else
        spectral_std = 0;
    end
    
    % 5. Energia em bandas de frequência
    % Definir bandas de frequência (em Hz)
    bandas = [0, 500, 1000, 2000, 4000, 8000];
    energia_bandas = zeros(1, length(bandas)-1);
    
    for b = 1:(length(bandas)-1)
        idx = (freq >= bandas(b)) & (freq < bandas(b+1));
        energia_bandas(b) = sum(amplitude(idx).^2);
    end
    
    % 6. Razão entre energia em baixa e alta frequência
    low_freq = sum(amplitude(freq < 1000).^2);
    high_freq = sum(amplitude(freq >= 1000).^2);
    
    if high_freq > 0
        razao_low_high = low_freq / high_freq;
    else
        razao_low_high = 0;
    end
    
    % 8. Roll-off espectral (frequência abaixo da qual está 85% da energia)
    if energia_total > 0
        rolloff_idx = find(energia_cumulativa >= 0.85 * energia_total, 1);
        
        if ~isempty(rolloff_idx)
            rolloff = freq(rolloff_idx);
        else
            rolloff = freq(end);
        end
    else
        rolloff = 0;
    end

    % 9. Número de picos espectrais
    [~, locs] = findpeaks(amplitude, freq, 'MinPeakHeight', max(amplitude)*0.6, 'MinPeakDistance', 40, 'MinPeakProminence', 0.001);
    num_picos = length(locs);
    
    % Armazenar características na estrutura
    audioData(i).features_espectrais.max_amp = maxAmp;
    audioData(i).features_espectrais.max_freq = maxFreq;
    audioData(i).features_espectrais.centroide = centroide;
    audioData(i).features_espectrais.sef95 = sef95;
    audioData(i).features_espectrais.spectral_std = spectral_std;
    audioData(i).features_espectrais.energia_bandas = energia_bandas;
    audioData(i).features_espectrais.razao_low_high = razao_low_high;
    audioData(i).features_espectrais.rolloff = rolloff;
    audioData(i).features_espectrais.num_picos = num_picos;
    audioData(i).features_espectrais.locs = locs;
    
    % Exibir progresso a cada 50 arquivos
    if mod(i, 50) == 0
        fprintf('Características espectrais centroid: %d / %d\n', i, audioData(i).features_espectrais.centroide);
        fprintf('Características espectrais calculadas para %d/%d sinais...\n', i, length(audioData));
    end
end

fprintf('Cálculo das características espectrais concluído.\n');

%% 14. Visualização e análise das características espectrais
fprintf('Analisando características espectrais...\n');

% Extrair características e dígitos para análise
digitos_todos = [audioData.digito]';

% Inicializar arrays para armazenar as características
max_freq = zeros(length(audioData), 1);
centroide = zeros(length(audioData), 1);
sef95 = zeros(length(audioData), 1);
spectral_std = zeros(length(audioData), 1);
razao_low_high = zeros(length(audioData), 1);
rolloff = zeros(length(audioData), 1);
energia_bandas = zeros(length(audioData), 5); % 5 bandas
num_picos = zeros(length(audioData), 1);

% Extrair características
for i = 1:length(audioData)
    % Verificar se cada campo existe antes de acessá-lo
    if isfield(audioData(i).features_espectrais, 'max_freq')
        max_freq(i) = audioData(i).features_espectrais.max_freq;
    else
        max_freq(i) = 0;
    end
    
    if isfield(audioData(i).features_espectrais, 'centroide')
        centroide(i) = audioData(i).features_espectrais.centroide;
    else
        centroide(i) = 0;
    end
    
    if isfield(audioData(i).features_espectrais, 'sef95')
        sef95(i) = audioData(i).features_espectrais.sef95;
    else
        sef95(i) = 0;
    end
    
    if isfield(audioData(i).features_espectrais, 'spectral_std')
        spectral_std(i) = audioData(i).features_espectrais.spectral_std;
    else
        spectral_std(i) = 0;
    end
    
    if isfield(audioData(i).features_espectrais, 'razao_low_high')
        razao_low_high(i) = audioData(i).features_espectrais.razao_low_high;
    else
        razao_low_high(i) = 0;
    end
    
    if isfield(audioData(i).features_espectrais, 'rolloff')
        rolloff(i) = audioData(i).features_espectrais.rolloff;
    else
        rolloff(i) = 0;
    end
    
    if isfield(audioData(i).features_espectrais, 'energia_bandas')
        energia_bandas(i,:) = audioData(i).features_espectrais.energia_bandas;
    else
        energia_bandas(i,:) = zeros(1,5);
    end
    if isfield(audioData(i).features_espectrais, 'num_picos')
        num_picos(i) = audioData(i).features_espectrais.num_picos;
    else
        num_picos(i) = 0;
    end
end

% Calcular razões entre bandas de energia
razao_banda1_banda3 = energia_bandas(:,1) ./ (energia_bandas(:,3) + eps); % Evitar divisão por zero
razao_banda2_banda4 = energia_bandas(:,2) ./ (energia_bandas(:,4) + eps);

% Boxplot para análise de características por dígito
figure('Name', 'Boxplot de Características Espectrais por Dígito', 'Position', [100, 100, 1200, 800]);

subplot(2, 3, 1);
boxplot(centroide, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Centroide Espectral por Dígito');
ylabel('Frequência (Hz)');
grid on;

subplot(2, 3, 2);
boxplot(sef95, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Spectral Edge Frequency (95%) por Dígito');
ylabel('Frequência (Hz)');
grid on;

subplot(2, 3, 3);
boxplot(razao_low_high, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Razão Baixa/Alta Frequência por Dígito');
ylabel('Razão');
grid on;

subplot(2, 3, 4);
boxplot(rolloff, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Roll-off Espectral por Dígito');
ylabel('Frequência (Hz)');
grid on;

subplot(2, 3, 5);
boxplot(razao_banda1_banda3, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Razão Banda 0-500Hz / Banda 1000-2000Hz');
ylabel('Razão');
grid on;

subplot(2, 3, 6);
boxplot(razao_banda2_banda4, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Razão Banda 500-1000Hz / Banda 2000-4000Hz');
ylabel('Razão');
grid on;

% Gráfico de dispersão para análise de correlação entre características
figure('Name', 'Correlação entre Características Espectrais', 'Position', [100, 100, 1200, 800]);

subplot(2, 2, 1);
scatter(centroide, sef95, 15, digitos_todos, 'filled');
title('Centroide vs. SEF95');
xlabel('Centroide (Hz)');
ylabel('SEF95 (Hz)');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;

subplot(2, 2, 2);
scatter(centroide, razao_low_high, 15, digitos_todos, 'filled');
title('Centroide vs. Razão Baixa/Alta Frequência');
xlabel('Centroide (Hz)');
ylabel('Razão Baixa/Alta Freq.');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;

subplot(2, 2, 3);
scatter3(centroide, num_picos, rolloff, 30, digitos_todos, 'filled');
title('Centroide vs. Numero de picos vs. Roll-off');
xlabel('Centroide (Hz)');
ylabel('Numero de picos');
zlabel('Roll-off (Hz)');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;
view(30, 30);

subplot(2, 2, 4);
scatter3(centroide, razao_low_high, rolloff, 30, digitos_todos, 'filled');
title('Centroide vs. Razão Baixa/Alta vs. Roll-off');
xlabel('Centroide (Hz)');
ylabel('Razão Baixa/Alta');
zlabel('Roll-off (Hz)');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;
view(30, 30);

% Com base na análise visual, identificar as três melhores características
fprintf('As três características espectrais que parecem ser mais relevantes para discriminação dos dígitos são:\n');
fprintf('1. Centroide Espectral\n');
fprintf('2. Razão de Energia Baixa/Alta Frequência\n');
fprintf('3. Razão entre bandas de energia específicas\n');

%% 15. Atualizar o ficheiro .mat com a estrutura de dados
fprintf('Atualizando ficheiro .mat...\n');

% Salvar a estrutura de dados atualizada
save('meta2_audiodata.mat', 'audioData');

fprintf('Meta 2 concluída! Dados salvos em "meta2_audiodata.mat".\n');