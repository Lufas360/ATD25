
%% 1. Criação da estrutura de dados para armazenar informações dos áudios
clear all; close all; clc;

% Caminho para a pasta do participante selecionado
dataPath = 'data/01/';

% Inicializar a estrutura de dados
audioData = struct('diretorio', {}, 'nome_ficheiro', {}, 'participante', {}, ...
                  'digito', {}, 'repeticao', {}, 'fs', {}, 'sinal_original', {}, ...
                  'sinal_processado', {}, 'tempo', {}, 'features_temporais', {});

% Verificar se o caminho existe
if ~isfolder(dataPath)
    error('Pasta de dados não encontrada. Verifique o caminho: %s', dataPath);
end

% Obter lista de arquivos .wav
wavFiles = dir(fullfile(dataPath, '*.wav'));

% Verificar se existem arquivos .wav na pasta
if isempty(wavFiles)
    error('Nenhum arquivo .wav encontrado na pasta %s', dataPath);
end

fprintf('Encontrados %d arquivos .wav para processamento.\n', length(wavFiles));

%% 2. Importação dos sinais de áudio para a estrutura de dados
fprintf('Importando sinais de áudio...\n');

for i = 1:length(wavFiles)
    % Obter nome completo do arquivo
    filename = fullfile(wavFiles(i).folder, wavFiles(i).name);
    
    % Extrair informações do nome do arquivo (formato: [digito]_[repeticao].wav)
    [~, name, ext] = fileparts(wavFiles(i).name);
    parts = split(name, '_');
    
    % Verificar se o nome do arquivo está no formato esperado
    if length(parts) >= 2
        digito = str2double(parts{1});
        repeticao = str2double(parts{3});
    else
        warning('Formato de nome de arquivo não reconhecido: %s', wavFiles(i).name);
        digito = -1;
        repeticao = -1;
    end
    
    % Ler o arquivo de áudio
    [sinal, fs] = audioread(filename);
    
    % Calcular o vetor de tempo
    tempo = (0:length(sinal)-1)' / fs;
    
    % Armazenar na estrutura de dados
    audioData(i).diretorio = wavFiles(i).folder;
    audioData(i).nome_ficheiro = [name, ext];
    audioData(i).participante = '01'; % O participante escolhido
    audioData(i).digito = digito;
    audioData(i).repeticao = repeticao;
    audioData(i).fs = fs;
    audioData(i).sinal_original = sinal;
    audioData(i).tempo = tempo;
    
    % Inicializar campos que serão preenchidos posteriormente
    audioData(i).sinal_processado = [];
    audioData(i).features_temporais = struct();
    
    % Exibir progresso a cada 50 arquivos
    if mod(i, 50) == 0
        fprintf('Processados %d/%d arquivos...\n', i, length(wavFiles));
    end
end

fprintf('Importação concluída. Estrutura de dados criada com %d registros.\n', length(audioData));

%% 3. Reproduzir e representar graficamente alguns exemplos de sinais
% Selecionar um exemplo de cada dígito (repetição 5)
digitos = 0:9;
repeticao = 5;
exemplos = [];

% Encontrar exemplos para cada dígito
for d = digitos
    idx = find([audioData.digito] == d & [audioData.repeticao] == repeticao, 1);
    if ~isempty(idx)
        exemplos = [exemplos, idx];
    else
        warning('Exemplo não encontrado para dígito %d, repetição %d', d, repeticao);
    end
end

% Criar a figura para exibir os exemplos
if ~isempty(exemplos)
    figure('Name', 'Gráficos dos Áudios Originais', 'Position', [100, 100, 1200, 800]);
    
    for i = 1:length(exemplos)
        idx = exemplos(i);
        subplot(5, 2, i);
        plot(audioData(idx).tempo, audioData(idx).sinal_original, 'b');
        title(sprintf('Dígito %d; Repetição %d', audioData(idx).digito, audioData(idx).repeticao));
        xlabel('Tempo [s]');
        ylabel('Amplitude');
        grid on;
    end
    
    % Ajustar espaçamento dos subplots
    tight = get(gcf, 'Position');
    set(gcf, 'Position', tight);
end

%% 4. Pré-processamento dos sinais
fprintf('Iniciando pré-processamento dos sinais...\n');

for i = 1:length(audioData)
    % Obter o sinal
    sinal = audioData(i).sinal_original;
    fs = audioData(i).fs;
    
    % 1. Retirar o silêncio inicial (usando a energia do sinal)
    janela = round(0.01 * fs); % Janela de 10 ms
    sobreposicao = round(0.005 * fs); % Sobreposição de 5 ms

    energia = zeros(1, floor((length(sinal) - janela) / (janela - sobreposicao)));
    
    for j = 1:length(energia)
        inicio = (j-1) * (janela - sobreposicao) + 1;
        fim = inicio + janela - 1;
        if fim <= length(sinal)
            energia(j) = sum(sinal(inicio:fim).^2);
        end
    end
    
    % Determinar o início do sinal (onde a energia ultrapassa um limiar)
    limiar_energia = 0.1 * max(energia); % 10% da energia máxima
    idx_inicio = find(energia > limiar_energia, 1);
    
    if ~isempty(idx_inicio)
        amostra_inicio = max(1, (idx_inicio-1) * (janela - sobreposicao) + 1);
        sinal = sinal(amostra_inicio:end);
    end
    
    % 2. Normalizar a amplitude
    sinal = sinal / max(abs(sinal));
    
    % 3. Padronizar a duração (adicionar/retirar silêncio no final)
    duracao_padrao = 0.8; % Duração padrão em segundos
    amostras_padrao = round(duracao_padrao * fs);
    
    % Ajustar o tamanho do sinal
    if length(sinal) < amostras_padrao
        % Adicionar zeros no final (silêncio)
        sinal = [sinal; zeros(amostras_padrao - length(sinal), 1)];
    elseif length(sinal) > amostras_padrao
        % Cortar o sinal
        sinal = sinal(1:amostras_padrao);
    end
    
    % Atualizar o sinal processado na estrutura
    audioData(i).sinal_processado = sinal;
    
    % Atualizar o vetor de tempo para o sinal processado
    audioData(i).tempo_processado = (0:length(sinal)-1)' / fs;
    
    % Exibir progresso a cada 50 arquivos
    if mod(i, 50) == 0
        fprintf('Pré-processados %d/%d sinais...\n', i, length(audioData));
    end
end

fprintf('Pré-processamento concluído.\n');

%% 5. Representar graficamente os sinais após o pré-processamento
% Usar os mesmos exemplos do ponto 3
if ~isempty(exemplos)
    figure('Name', 'Gráficos dos Áudios Pré-processados', 'Position', [100, 100, 1200, 800]);
    
    for i = 1:length(exemplos)
        idx = exemplos(i);
        subplot(5, 2, i);
        plot(audioData(idx).tempo_processado, audioData(idx).sinal_processado, 'r');
        title(sprintf('Dígito %d; Repetição %d (Pré-processado)', audioData(idx).digito, audioData(idx).repeticao));
        xlabel('Tempo [s]');
        ylabel('Amplitude');
        grid on;
    end
    
    % Ajustar espaçamento dos subplots
    tight = get(gcf, 'Position');
    set(gcf, 'Position', tight);
end

%% 7. Calcular características temporais dos sinais
fprintf('Calculando características temporais dos sinais...\n');

for i = 1:length(audioData)
    sinal = audioData(i).sinal_processado;
    fs = audioData(i).fs;
    tempo = audioData(i).tempo_processado;
    
    % 1. Energia total
    energia_total = sum(sinal.^2);
    
    % 2. Dividir o sinal em 4 partes e calcular a energia em cada parte
    n_partes = 4;
    tamanho_parte = floor(length(sinal) / n_partes);
    energia_partes = zeros(1, n_partes);
    
    for p = 1:n_partes
        inicio = (p-1) * tamanho_parte + 1;
        fim = min(p * tamanho_parte, length(sinal));
        energia_partes(p) = sum(sinal(inicio:fim).^2);
    end
    
    % 3. Amplitude máxima
    amp_max = max(abs(sinal));
    
    % 4. Taxa de cruzamentos por zero
    zcr = sum(abs(diff(sign(sinal)))) / (2 * length(sinal));
    
    % 5. Desvio padrão da amplitude
    amp_std = std(sinal);
    
    % 6. Razão entre energias (primeiras 2 partes vs últimas 2 partes)
    razao_energia = sum(energia_partes(1:2)) / sum(energia_partes(3:4));
    
    % 7. Duração efetiva do sinal (tempo em que a amplitude > 10% do máximo)
    limiar_amp = 0.1 * amp_max;
    duracao_efetiva = sum(abs(sinal) > limiar_amp) / fs;
    
    % Armazenar as características na estrutura
    audioData(i).features_temporais.energia_total = energia_total;
    audioData(i).features_temporais.energia_partes = energia_partes;
    audioData(i).features_temporais.amp_max = amp_max;
    audioData(i).features_temporais.zcr = zcr;
    audioData(i).features_temporais.amp_std = amp_std;
    audioData(i).features_temporais.razao_energia = razao_energia;
    audioData(i).features_temporais.duracao_efetiva = duracao_efetiva;
    
    % Exibir progresso a cada 50 arquivos
    if mod(i, 50) == 0
        fprintf('Características calculadas para %d/%d sinais...\n', i, length(audioData));
    end
end

fprintf('Cálculo de características temporais concluído.\n');

%% 8. Visualização e análise das características extraídas
% Extrair todas as características e os respectivos dígitos para análise usando loops
digitos_todos = [audioData.digito]';

% Inicializar arrays para armazenar as características
energia_total = zeros(length(audioData), 1);
zcr = zeros(length(audioData), 1);
amp_std = zeros(length(audioData), 1);
duracao_efetiva = zeros(length(audioData), 1);
razao_energia = zeros(length(audioData), 1);
energia_partes = zeros(length(audioData), 4);

% Extrair características usando um loop
for i = 1:length(audioData)
    energia_total(i) = audioData(i).features_temporais.energia_total;
    zcr(i) = audioData(i).features_temporais.zcr;
    amp_std(i) = audioData(i).features_temporais.amp_std;
    duracao_efetiva(i) = audioData(i).features_temporais.duracao_efetiva;
    razao_energia(i) = audioData(i).features_temporais.razao_energia;
    energia_partes(i,:) = audioData(i).features_temporais.energia_partes;
end

% Criar razões adicionais entre as partes para análise
razao_energia_12 = energia_partes(:,1) ./ energia_partes(:,2);
razao_energia_13 = energia_partes(:,1) ./ energia_partes(:,3);
razao_energia_14 = energia_partes(:,1) ./ energia_partes(:,4);

% Boxplot para análise de características por dígito
figure('Name', 'Boxplot de Características por Dígito', 'Position', [100, 100, 1200, 800]);

subplot(2, 2, 1);
boxplot(energia_total, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Energia Total por Dígito');
ylabel('Energia');
grid on;

subplot(2, 2, 2);
boxplot(zcr, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Taxa de Cruzamentos por Zero por Dígito');
ylabel('ZCR');
grid on;

subplot(2, 2, 3);
boxplot(amp_std, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Desvio Padrão da Amplitude por Dígito');
ylabel('Desvio Padrão');
grid on;

subplot(2, 2, 4);
boxplot(duracao_efetiva, digitos_todos, 'Labels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
title('Duração Efetiva por Dígito');
ylabel('Duração (s)');
grid on;

% Análise de correlação entre características
figure('Name', 'Correlação entre Características', 'Position', [100, 100, 1200, 800]);

subplot(2, 2, 1);
scatter(energia_total, zcr, 15, digitos_todos, 'filled');
title('Energia Total vs. ZCR');
xlabel('Energia Total');
ylabel('ZCR');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;

subplot(2, 2, 2);
scatter(energia_total, duracao_efetiva, 15, digitos_todos, 'filled');
title('Energia Total vs. Duração Efetiva');
xlabel('Energia Total');
ylabel('Duração Efetiva (s)');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;

subplot(2, 2, 3);
scatter(razao_energia, zcr, 15, digitos_todos, 'filled');
title('Razão de Energia vs. ZCR');
xlabel('Razão de Energia (1ª+2ª parte)/(3ª+4ª parte)');
ylabel('ZCR');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;

subplot(2, 2, 4);
scatter3(zcr, duracao_efetiva, razao_energia, 30, digitos_todos, 'filled');
title('ZCR vs. Duração Efetiva vs. Razão de Energia');
xlabel('ZCR');
ylabel('Duração Efetiva (s)');
zlabel('Razão de Energia');
colorbar('Ticks', 0:9, 'TickLabels', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
grid on;
view(30, 30);

% Com base na análise visual dos gráficos, identificar as três melhores características
fprintf('As três características temporais que parecem ser mais relevantes para discriminação dos dígitos são:\n');
fprintf('1. Taxa de Cruzamentos por Zero (ZCR)\n');
fprintf('2. Razão de Energia entre partes\n');
fprintf('3. Duração Efetiva\n');

% Os valores específicos podem variar dependendo dos dados analisados

%% 9. Remover os sinais de áudio importados e guardar a estrutura num ficheiro .mat
% Criar uma cópia da estrutura sem os sinais para economizar espaço
audioDataCompact = audioData;

% Remover os sinais de áudio
for i = 1:length(audioDataCompact)
    audioDataCompact(i).sinal_original = [];
end

% Salvar a estrutura de dados compacta
save('meta1_audiodata.mat', 'audioDataCompact');

fprintf('Meta 1 concluída! Dados salvos em "meta1_audiodata.mat".\n');