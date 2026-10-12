
clear;
clc;
close all;

% ASTRA-Link: LEO orbit and ground station visibility

% Simulation time (UTC)
startTime = datetime(2026,10,9,0,0,0, ...
    'TimeZone','UTC');
stopTime = startTime + hours(24);
sampleTime = 60;  % seconds

% Earth and satellite parameters
Re = 6378137;      % Earth equatorial radius (m)
altitude = 500e3;  % Assumed orbital altitude (m)
semiMajorAxis = Re + altitude;

eccentricity = 0;
inclination = 51.6;   % degrees
RAAN = 0;             % degrees
argPerigee = 0;       % degrees
trueAnomaly = 0;      % degrees

% Create satellite scenario
sc = satelliteScenario(startTime,stopTime,sampleTime);

% Add satellite using orbital elements
sat = satellite(sc,semiMajorAxis,eccentricity, ...
    inclination,RAAN,argPerigee,trueAnomaly, ...
    Name="ASTRA-Link");

% Hyderabad ground station (approximate coordinates)
gs = groundStation(sc,17.385,78.486, ...
    Name="Hyderabad Ground Station", ...
    MinElevationAngle=10);

% Calculate satellite visibility
ac = access(sat,gs);
intervals = accessIntervals(ac);


% Display access windows
disp('Satellite visibility windows:');
disp(intervals);

% Visualize the satellite scenario
viewer = satelliteScenarioViewer(sc);
play(sc);
