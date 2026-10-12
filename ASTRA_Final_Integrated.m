
clear;
clc;
close all;

%% ASTRA-Link: Integrated Orbit and Communication Analysis
% Illustrative LEO satellite-to-Hyderabad ground-station link
% Includes orbit, visibility, link budget and antenna optimization.

%% 1. Simulation setup
startTime = datetime(2026,10,9,0,0,0,'TimeZone','UTC');
stopTime = startTime + hours(24);
sampleTime = 60;                 % seconds

sc = satelliteScenario(startTime,stopTime,sampleTime);

%% 2. Satellite orbit
Re = 6378137;                    % Earth equatorial radius (m)
altitude = 500e3;                % Assumed altitude: 500 km
semiMajorAxis = Re + altitude;

eccentricity = 0;
inclination = 51.6;              % degrees
RAAN = 0;
argPerigee = 0;
trueAnomaly = 0;

sat = satellite(sc,semiMajorAxis,eccentricity, ...
    inclination,RAAN,argPerigee,trueAnomaly, ...
    Name="ASTRA-Link");

%% 3. Hyderabad ground station
gsLat = 17.385;
gsLon = 78.486;
minElevation = 10;               % degrees

gs = groundStation(sc,gsLat,gsLon, ...
    Name="Hyderabad Ground Station", ...
    MinElevationAngle=minElevation);

ac = access(sat,gs);
accessWindows = accessIntervals(ac);

disp(' ');
disp('===== ASTRA-Link Visibility Windows =====');
disp(accessWindows);

fprintf('Number of visibility windows: %d\n', ...
    height(accessWindows));

%% 4. Obtain satellite positions and access status
% Positions are returned in Earth-centred, Earth-fixed coordinates.
[satPos,~,t] = states(sat,CoordinateFrame="ecef");

satPos = squeeze(satPos);

if size(satPos,1) ~= 3
    satPos = satPos.';
end

t = t(:);

visible = accessStatus(ac);
visible = logical(visible(:));

% Ensure arrays have matching sample counts.
N = min([size(satPos,2),numel(t),numel(visible)]);
satPos = satPos(:,1:N);
t = t(1:N);
visible = visible(1:N);

%% 5. Ground station ECEF coordinates (WGS84)
a = 6378137;                     % Semi-major axis (m)
f = 1/298.257223563;             % Flattening
e2 = f*(2-f);

lat = deg2rad(gsLat);
lon = deg2rad(gsLon);
h = 0;                           % Assumed ground altitude (m)

Nlat = a/sqrt(1-e2*sin(lat)^2);

groundPos = [ ...
    (Nlat+h)*cos(lat)*cos(lon);
    (Nlat+h)*cos(lat)*sin(lon);
    (Nlat*(1-e2)+h)*sin(lat)];

%% 6. Slant range and link geometry
deltaPos = satPos - groundPos;
slantRange_km = vecnorm(deltaPos,2,1)'/1000;

% Exclude any invalid or non-positive ranges.
valid = visible & isfinite(slantRange_km) ...
    & slantRange_km > 0;

%% 7. Communication system assumptions
frequency_GHz = 2.2;
transmitPower_W = 5;
txGain_dBi = 3;
otherLosses_dB = 2;

bandwidth_Hz = 1e6;
noiseFigure_dB = 3;
requiredSNR_dB = 6;

% Compare ground-station receiver antenna gains.
rxGainOptions_dBi = [15 20 25 30];

txPower_dBW = 10*log10(transmitPower_W);

% Thermal noise power, using -174 dBm/Hz at approximately 290 K.
noisePower_dBm = -174 ...
    + 10*log10(bandwidth_Hz) ...
    + noiseFigure_dB;

%% 8. Calculate link margin at every time sample
% Free-space path loss in dB; range must be in kilometres.
FSPL_dB = 92.45 ...
    + 20*log10(frequency_GHz) ...
    + 20*log10(max(slantRange_km,eps));

receivedPower_dBm = txPower_dBW ...
    + txGain_dBi ...
    + FSPL_dB*0 ...       % Placeholder removed below
    + 30;

% Correct received power using the full link-budget equation.
receivedPower_dBW = txPower_dBW ...
    + txGain_dBi ...
    + rxGainOptions_dBi(1)*0 ...
    - FSPL_dB ...
    - otherLosses_dB;

% SNR and margin are evaluated separately for each antenna gain.
linkMargin_dB = nan(N,numel(rxGainOptions_dBi));

for k = 1:numel(rxGainOptions_dBi)

    Pr_dBW = txPower_dBW ...
        + txGain_dBi ...
        + rxGainOptions_dBi(k) ...
        - FSPL_dB ...
        - otherLosses_dB;

    Pr_dBm = Pr_dBW + 30;
    SNR_dB = Pr_dBm - noisePower_dBm;

    linkMargin_dB(:,k) = SNR_dB - requiredSNR_dB;
end

% Display link margin only when the satellite is visible.
linkMargin_dB(~valid,:) = NaN;

%% 9. Print simulation summary
fprintf('\n===== ASTRA-Link Communication Parameters =====\n');
fprintf('Carrier frequency: %.2f GHz\n',frequency_GHz);
fprintf('Transmit power: %.2f W\n',transmitPower_W);
fprintf('Bandwidth: %.2f MHz\n',bandwidth_Hz/1e6);
fprintf('Receiver noise power: %.2f dBm\n',noisePower_dBm);
fprintf('Required SNR: %.2f dB\n',requiredSNR_dB);
fprintf('Visible samples: %d of %d\n',nnz(valid),N);

if any(valid)
    fprintf('Minimum visible slant range: %.2f km\n', ...
        min(slantRange_km(valid)));
    fprintf('Maximum visible slant range: %.2f km\n', ...
        max(slantRange_km(valid)));
else
    warning('No valid visible samples were found.');
end

%% 10. Compare antenna gains
nGain = numel(rxGainOptions_dBi);

MinimumMargin_dB = nan(nGain,1);
AverageMargin_dB = nan(nGain,1);
MaximumMargin_dB = nan(nGain,1);
Meets3dBTarget = false(nGain,1);

for k = 1:nGain
    margins = linkMargin_dB(valid,k);
    margins = margins(isfinite(margins));

    if ~isempty(margins)
        MinimumMargin_dB(k) = min(margins);
        AverageMargin_dB(k) = mean(margins);
        MaximumMargin_dB(k) = max(margins);
        Meets3dBTarget(k) = min(margins) >= 3;
    end
end

Results = table(rxGainOptions_dBi(:), ...
    MinimumMargin_dB,AverageMargin_dB, ...
    MaximumMargin_dB,Meets3dBTarget, ...
    'VariableNames',{'RxGain_dBi','MinMargin_dB', ...
    'MeanMargin_dB','MaxMargin_dB','Meets3dBTarget'});

disp(' ');
disp('===== ASTRA-Link Antenna Gain Comparison =====');
disp(Results);

%% 11. Plot link margin versus time
figure;
plot(t,linkMargin_dB,'LineWidth',1.3);
hold on;
yline(0,'k--','Zero-margin threshold');
yline(3,'r:','3 dB design target','LineWidth',1.2);
grid on;

xlabel('Time (UTC)');
ylabel('Link margin (dB)');
title('ASTRA-Link: Link Margin During Satellite Visibility');
legend('15 dBi','20 dBi','25 dBi','30 dBi', ...
    'Zero margin','3 dB target','Location','best');

%% 12. Plot worst-case margin versus antenna gain
figure;
plot(rxGainOptions_dBi,MinimumMargin_dB, ...
    '-o','LineWidth',1.6,'MarkerSize',7);
hold on;
yline(0,'k--','Zero-margin threshold');
yline(3,'r:','3 dB design target','LineWidth',1.2);
grid on;

xlabel('Ground-station receiver antenna gain (dBi)');
ylabel('Minimum visible link margin (dB)');
title('ASTRA-Link: Worst-Case Link Margin Optimization');

%% 13. Plot slant range during visible passes
figure;
plot(t(valid),slantRange_km(valid),'LineWidth',1.3);
grid on;

xlabel('Time (UTC)');
ylabel('Slant range (km)');
title('ASTRA-Link: Satellite-to-Ground-Station Slant Range');

%% 14. Recommended design based on the simulated 3 dB target
acceptable = Results.Meets3dBTarget;

fprintf('\n===== ASTRA-Link Design Recommendation =====\n');

if any(acceptable)
    firstGood = find(acceptable,1,'first');
    selectedGain = Results.RxGain_dBi(firstGood);

    fprintf('Lowest tested gain meeting the 3 dB target: %.1f dBi\n', ...
        selectedGain);
    fprintf('Minimum simulated margin at this gain: %.2f dB\n', ...
        Results.MinMargin_dB(firstGood));
else
    fprintf(['None of the tested antenna gains met the 3 dB ' ...
        'target at every visible sample.\n']);
    fprintf('Consider adjusting the system assumptions and rerunning.\n');
end

fprintf(['\nNote: This is an illustrative free-space link budget. ' ...
    'It does not yet model terrain, interference, antenna pointing, ' ...
    'fading, coding gain or a detailed receiver implementation.\n']);
fprintf('Simulation finished.\n');
