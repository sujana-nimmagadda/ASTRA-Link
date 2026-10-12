
clear;
clc;
close all;

% ASTRA-Link: Integrated Orbit and Communication Simulation

%% 1. Simulation setup
startTime = datetime(2026,10,9,0,0,0,'TimeZone','UTC');
stopTime = startTime + hours(24);
sampleTime = 60;

%% 2. Satellite orbit parameters
Re = 6378137;          % Earth equatorial radius (m)
altitude = 500e3;      % Assumed orbital altitude (m)
semiMajorAxis = Re + altitude;

eccentricity = 0;
inclination = 51.6;
RAAN = 0;
argPerigee = 0;
trueAnomaly = 0;

%% 3. Create satellite scenario
sc = satelliteScenario(startTime,stopTime,sampleTime);

sat = satellite(sc,semiMajorAxis,eccentricity, ...
    inclination,RAAN,argPerigee,trueAnomaly, ...
    Name="ASTRA-Link");

%% 4. Create Hyderabad ground station
gs = groundStation(sc,17.385,78.486, ...
    Name="Hyderabad Ground Station", ...
    MinElevationAngle=10);

%% 5. Calculate satellite visibility
ac = access(sat,gs);
intervals = accessIntervals(ac);

disp('ASTRA-Link visibility windows:');
disp(intervals);

fprintf('Number of visibility windows: %d\n', ...
    height(intervals));

%% 6. Get satellite position in Earth-fixed coordinates
t = startTime:seconds(sampleTime):stopTime;

[pos,~] = states(sat,CoordinateFrame="ecef");
satPos = squeeze(pos);

% Ensure position array has 3 rows (X, Y, Z)
if size(satPos,1) ~= 3
    satPos = satPos';
end

% Use only the available satellite samples
numSamples = size(satPos,2);
t = t(1:numSamples);

%% 7. Calculate Hyderabad ground station coordinates
% WGS84 Earth ellipsoid
lat = deg2rad(17.385);
lon = deg2rad(78.486);
h = 0;  % Assumed ground station altitude (m)

a = 6378137;
f = 1/298.257223563;
e2 = f*(2-f);

Nlat = a/sqrt(1-e2*sin(lat)^2);

gsX = (Nlat+h)*cos(lat)*cos(lon);
gsY = (Nlat+h)*cos(lat)*sin(lon);
gsZ = (Nlat*(1-e2)+h)*sin(lat);

groundPos = [gsX; gsY; gsZ];

%% 8. Calculate slant range
slantRange_km = vecnorm(satPos-groundPos,2,1)/1000;

% Avoid invalid logarithms if any range is zero
slantRange_km(slantRange_km <= 0) = NaN;

%% 9. Communication parameters
frequency_GHz = 2.2;
transmitPower_W = 5;
txGain_dBi = 3;
rxGain_dBi = 28;
otherLosses_dB = 2;

bandwidth_Hz = 1e6;
noiseFigure_dB = 3;
requiredSNR_dB = 6;
%% 10. Calculate communication link budget
txPower_dBW = 10*log10(transmitPower_W);

fspl_dB = 92.45 ...
    + 20*log10(frequency_GHz) ...
    + 20*log10(slantRange_km);

receivedPower_dBm = txPower_dBW ...
    + txGain_dBi + rxGain_dBi ...
    - fspl_dB - otherLosses_dB + 30;

noisePower_dBm = -174 ...
    + 10*log10(bandwidth_Hz) ...
    + noiseFigure_dB;

SNR_dB = receivedPower_dBm - noisePower_dBm;
linkMargin_dB = SNR_dB - requiredSNR_dB;

%% 11. Determine actual visibility samples
% Calculate elevation using the ground station's local vertical.
% Convert satellite-ground displacement into local ENU coordinates.

dx = satPos(1,:) - gsX;
dy = satPos(2,:) - gsY;
dz = satPos(3,:) - gsZ;

east = -sin(lon).*dx + cos(lon).*dy;

north = -sin(lat).*cos(lon).*dx ...
        - sin(lat).*sin(lon).*dy ...
        + cos(lat).*dz;

up = cos(lat).*cos(lon).*dx ...
     + cos(lat).*sin(lon).*dy ...
     + sin(lat).*dz;

elevation_deg = atan2d(up,sqrt(east.^2+north.^2));

visible = elevation_deg >= 10;

% Hide communication estimates when the satellite is not visible
visibleRange_km = slantRange_km;
visibleRange_km(~visible) = NaN;

visibleMargin_dB = linkMargin_dB;
visibleMargin_dB(~visible) = NaN;

visiblePower_dBm = receivedPower_dBm;
visiblePower_dBm(~visible) = NaN;

%% 12. Plot slant range during visibility
figure;
plot(t,visibleRange_km,'LineWidth',1.5);
grid on;
xlabel('Time (UTC)');
ylabel('Slant range (km)');
title('ASTRA-Link: Range During Hyderabad Visibility');

%% 13. Plot received power during visibility
figure;
plot(t,visiblePower_dBm,'LineWidth',1.5);
grid on;
xlabel('Time (UTC)');
ylabel('Received power (dBm)');
title('ASTRA-Link: Received Power During Visibility');

%% 14. Plot link margin during visibility
figure;
plot(t,visibleMargin_dB,'LineWidth',1.5);
hold on;
yline(0,'--');
grid on;
xlabel('Time (UTC)');
ylabel('Link margin (dB)');
title('ASTRA-Link: Link Margin During Visibility');
legend('Estimated link margin','Zero-margin threshold', ...
    'Location','best');

%% 15. Display summary
fprintf('\nASTRA-Link integrated simulation summary\n');
fprintf('Carrier frequency: %.2f GHz\n',frequency_GHz);
fprintf('Transmit power: %.2f W\n',transmitPower_W);
fprintf('Bandwidth: %.2f MHz\n',bandwidth_Hz/1e6);
fprintf('Receiver noise power: %.2f dBm\n',noisePower_dBm);
fprintf('Visible samples: %d of %d\n',sum(visible),numSamples);

if any(visible)
    fprintf('Minimum visible slant range: %.2f km\n', ...
        min(slantRange_km(visible)));
    fprintf('Maximum visible slant range: %.2f km\n', ...
        max(slantRange_km(visible)));
    fprintf('Best estimated visible link margin: %.2f dB\n', ...
        max(linkMargin_dB(visible)));
else
    fprintf('No visible samples found at the selected time resolution.\n');
end

fprintf('\nSimulation finished.\n');

%% ASTRA-Link: Minimum Link Margin for Each Visibility Pass

fprintf('\nASTRA-Link pass-by-pass link margin analysis\n');

% Find continuous groups of visible samples
visible = visible(:);
linkMargin_dB = linkMargin_dB(:);
t = t(:);

edges = diff([false; visible; false]);
passStarts = find(edges == 1);
passEnds = find(edges == -1) - 1;

if isempty(passStarts)
    fprintf('No visible satellite passes found.\n');
else
    for k = 1:numel(passStarts)
        idx = passStarts(k):passEnds(k);
        margins = linkMargin_dB(idx);
        margins = margins(isfinite(margins));

        if isempty(margins)
            continue;
        end

        fprintf('\nPass %d\n', k);
        fprintf('  Start: %s UTC\n', ...
            char(string(t(passStarts(k)), ...
            'dd-MMM-yyyy HH:mm:ss')));
        fprintf('  End:   %s UTC\n', ...
            char(string(t(passEnds(k)), ...
            'dd-MMM-yyyy HH:mm:ss')));
        fprintf('  Minimum link margin: %.2f dB\n', min(margins));
        fprintf('  Maximum link margin: %.2f dB\n', max(margins));
        fprintf('  Average link margin: %.2f dB\n', mean(margins));

        if min(margins) >= 3
            fprintf('  Assessment: At least 3 dB margin at all sampled points.\n');
        elseif min(margins) >= 0
            fprintf('  Assessment: Positive margin, but below 3 dB at some points.\n');
        else
            fprintf('  Assessment: Link falls below the required SNR at some points.\n');
        end
    end
end
