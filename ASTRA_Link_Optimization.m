
%% ASTRA-Link: Complete Antenna Gain Optimization
% Satellite communication link-budget analysis
% Standalone MATLAB script

clear;
clc;
close all;

fprintf('============================================\n');
fprintf(' ASTRA-Link Antenna Gain Optimization\n');
fprintf('============================================\n');

%% 1. Communication Parameters

frequency_GHz = 2.2;       % Carrier frequency (GHz)
transmitPower_W = 5;       % Satellite transmitter power (W)
txGain_dBi = 3;            % Satellite transmit antenna gain (dBi)
otherLosses_dB = 2;        % Combined additional losses (dB)

bandwidth_Hz = 1e6;        % Receiver bandwidth (Hz)
noiseFigure_dB = 3;        % Receiver noise figure (dB)
requiredSNR_dB = 6;        % Assumed required SNR (dB)

%% 2. Slant-Range Scenarios
% Based on the ranges reported by ASTRA_Integrated.m.
% Middle range is an illustrative representative value.

range_km = [1090.38, 1313.77, 1537.16];

rangeNames = {'Near range', 'Representative range', ...
              'Far range'};

%% 3. Ground-Station Antenna Gains to Compare

rxGains_dBi = [15, 18, 20, 22, 25, 28, 30];

%% 4. Calculate Receiver Noise Power

txPower_dBW = 10*log10(transmitPower_W);

noisePower_dBm = -174 ...
    + 10*log10(bandwidth_Hz) ...
    + noiseFigure_dB;

fprintf('\nCommunication parameters:\n');
fprintf('Carrier frequency: %.2f GHz\n', frequency_GHz);
fprintf('Transmit power: %.2f W\n', transmitPower_W);
fprintf('Bandwidth: %.2f MHz\n', bandwidth_Hz/1e6);
fprintf('Receiver noise power: %.2f dBm\n', noisePower_dBm);
fprintf('Required SNR: %.2f dB\n', requiredSNR_dB);

%% 5. Calculate Free-Space Path Loss

fspl_dB = 92.45 ...
    + 20*log10(frequency_GHz) ...
    + 20*log10(range_km);

%% 6. Calculate Link Margin for Each Antenna Gain

linkMargin_dB = zeros(numel(rxGains_dBi), ...
                      numel(range_km));

for i = 1:numel(rxGains_dBi)

    receivedPower_dBW = txPower_dBW ...
        + txGain_dBi ...
        + rxGains_dBi(i) ...
        - fspl_dB ...
        - otherLosses_dB;

    receivedPower_dBm = receivedPower_dBW + 30;

    SNR_dB = receivedPower_dBm - noisePower_dBm;

    linkMargin_dB(i,:) = SNR_dB - requiredSNR_dB;

end

%% 7. Display Comparison Table

Results = table( ...
    rxGains_dBi(:), ...
    linkMargin_dB(:,1), ...
    linkMargin_dB(:,2), ...
    linkMargin_dB(:,3), ...
    min(linkMargin_dB,[],2), ...
    'VariableNames', { ...
    'RxGain_dBi', ...
    'Margin_Near_dB', ...
    'Margin_Mid_dB', ...
    'Margin_Far_dB', ...
    'WorstCaseMargin_dB'});

fprintf('\nASTRA-Link antenna gain comparison:\n');
disp(Results);

%% 8. Plot Link Margin Versus Antenna Gain

figure;

plot(rxGains_dBi, linkMargin_dB(:,1), '-o', ...
    'LineWidth', 1.5, 'MarkerSize', 6);
hold on;

plot(rxGains_dBi, linkMargin_dB(:,2), '-s', ...
    'LineWidth', 1.5, 'MarkerSize', 6);

plot(rxGains_dBi, linkMargin_dB(:,3), '-^', ...
    'LineWidth', 1.5, 'MarkerSize', 6);

yline(0, '--k', 'Zero-margin threshold');
yline(3, ':r', '3 dB design target');

grid on;
xlabel('Ground-station antenna gain (dBi)');
ylabel('Link margin (dB)');

title('ASTRA-Link: Link Margin vs Antenna Gain');

legend(rangeNames{1}, rangeNames{2}, ...
       rangeNames{3}, 'Location', 'northwest');

%% 9. Plot Worst-Case Margin

worstCaseMargin_dB = min(linkMargin_dB,[],2);

figure;

plot(rxGains_dBi, worstCaseMargin_dB, '-o', ...
    'LineWidth', 2, 'MarkerSize', 7);

hold on;
yline(0, '--k', 'Zero-margin threshold');
yline(3, ':r', '3 dB design target');

grid on;
xlabel('Ground-station antenna gain (dBi)');
ylabel('Worst-case link margin (dB)');

title('ASTRA-Link: Worst-Case Link Margin');

%% 10. Estimate Antenna Gain Required for Target Margin

% Margin increases by approximately 1 dB per 1 dB
% increase in receiver antenna gain in this model.

baselineGain_dBi = 15;
baselineFarMargin_dB = linkMargin_dB(1,3);

requiredGainZero_dBi = baselineGain_dBi ...
    - baselineFarMargin_dB;

requiredGain3dB_dBi = requiredGainZero_dBi + 3;
requiredGain6dB_dBi = requiredGainZero_dBi + 6;

fprintf('\nASTRA-Link optimization summary:\n');

fprintf('Baseline receiver gain: %.1f dBi\n', ...
    baselineGain_dBi);

fprintf('Baseline far-range margin: %.2f dB\n', ...
    baselineFarMargin_dB);

fprintf('Estimated gain for zero margin: %.2f dBi\n', ...
    requiredGainZero_dBi);

fprintf('Estimated gain for 3 dB margin: %.2f dBi\n', ...
    requiredGain3dB_dBi);

fprintf('Estimated gain for 6 dB margin: %.2f dBi\n', ...
    requiredGain6dB_dBi);

%% 11. Recommend a Gain from the Tested Options

idxRecommended = find(worstCaseMargin_dB >= 3, 1, 'first');

if isempty(idxRecommended)

    fprintf(['No tested antenna gain meets the 3 dB target ', ...
             'at every range.\n']);

else

    fprintf('Lowest tested gain meeting 3 dB target: %.1f dBi\n', ...
        rxGains_dBi(idxRecommended));

    fprintf('Its worst-case margin is %.2f dB.\n', ...
        worstCaseMargin_dB(idxRecommended));

end

fprintf('\nSimulation finished.\n');
