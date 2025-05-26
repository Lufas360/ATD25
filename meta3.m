%% Meta 3
% Luis Filipe Lopes Henriques
% 2021226162

%% 16. Carregar a estrutura de dados da Meta 2
clear all; close all; clc;

% Carregar os dados da meta anterior
fprintf('Carregando dados da Meta 2...\n');
load('meta2_audiodata.mat');

% Verificar se os dados foram carregados corretamente
if ~exist('audioData', 'var')
    error('Não foi possível carregar os dados da Meta 2. Verifique se o arquivo meta2_audiodata.mat existe.');
end


fprintf('Dados carregados com sucesso! Estrutura contém %d registos.\n', length(audioData));

%% 17. Classificar audio com as caracteristicas

% Array centroide / SEF95 /Razão Baixa vs. Alta Frequencia
dataCompare = zeros(4, length(audioData));
fprintf('\n\nArray centroide / SEF95 /Razão Baixa vs. Alta Frequencia')
for i = 1:length(audioData)
    dataCompare(1, i) = audioData(i).digito;
    dataCompare(2, i) = audioData(i).features_espectrais.centroide;
    dataCompare(3, i) = audioData(i).features_espectrais.sef95;
    dataCompare(4, i) = audioData(i).features_espectrais.razao_low_high;
end 


% Para todos os elementos ver 10 elementos mais proximos e escolher o mais frequente
digitosCorretos = 0;
for i = 1:length(audioData)
    % Calcular a distância euclidiana para todos os outros elementos
    distances = sqrt(sum((dataCompare(2:4, :) - dataCompare(2:4, i)).^2, 1));
    
    % Ignorar a distância para o próprio elemento
    distances(i) = inf;
    
    % Encontrar os 10 elementos mais próximos
    [~, idx] = mink(distances, 10);
    
    % Obter os dígitos correspondentes aos 10 elementos mais próximos
    nearestDigits = dataCompare(1, idx);
    %printf('Dígitos mais próximos: %s\n', num2str(nearestDigits(1)));
    
    % Determinar o dígito mais frequente
    mostFrequentDigit = mode(nearestDigits);
    
    % Atribuir o dígito mais frequente ao elemento atual
    audioData(i).predictedDigit = mostFrequentDigit;
    
    % Verificar se o dígito previsto é igual ao dígito correto
    if audioData(i).predictedDigit == audioData(i).digito
        digitosCorretos = digitosCorretos + 1;
    end
end

%% 18. Calcular a taxa de acerto
% Calcular a taxa de acerto
accuracy = (digitosCorretos / length(audioData)) * 100;
fprintf('Taxa de acerto: %.2f%%\n', accuracy);

% Calcular a taxa de acerto para cada dígito
uniqueDigits = unique([audioData.digito]);
accuracyPerDigit = zeros(length(uniqueDigits), 1);

for d = 1:length(uniqueDigits)
    digit = uniqueDigits(d);
    
    % Filtrar os elementos correspondentes ao dígito atual
    digitIndices = [audioData.digito] == digit;
    digitData = audioData(digitIndices);
    
    % Contar os acertos para o dígito atual
    correctPredictions = sum([digitData.predictedDigit] == digit);
    
    % Calcular a taxa de acerto para o dígito atual
    accuracyPerDigit(d) = (correctPredictions / length(digitData)) * 100;
    
    fprintf('Taxa de acerto para o dígito %d: %.2f%%\n', digit, accuracyPerDigit(d));
end

%% 19. Criar a estrutura de dados para a Meta 3
% Criar a estrutura de dados para a Meta 3
audioDataMeta3 = struct('digito', [], 'features_espectrais', [], 'predictedDigit', []);
for i = 1:length(audioData)
    audioDataMeta3(i).digito = audioData(i).digito;
    audioDataMeta3(i).features_espectrais = audioData(i).features_espectrais;
    audioDataMeta3(i).predictedDigit = audioData(i).predictedDigit;
end



