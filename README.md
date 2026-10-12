# ASTRA-Link: Satellite Communication Analysis

**SPACEFORGE 2026 — Design. Simulate. Innovate.**

ASTRA-Link is a MATLAB-based satellite communication project developed for SPACEFORGE 2026 at BVRIT Hyderabad College of Engineering for Women.

## Project Overview

The project explores satellite communication performance through link budget analysis, free-space path loss calculations, received power estimation, signal-to-noise ratio (SNR) analysis, and antenna gain optimization.

## Objectives

- Model a satellite communication link using MATLAB.
- Analyze the effect of satellite range on communication performance.
- Estimate received signal power and SNR.
- Evaluate link margin against a required SNR.
- Investigate receiver antenna gain improvements to enhance link performance.

## Tools and Technologies

- MATLAB
- Satellite communication fundamentals
- Link budget analysis
- Antenna gain optimization
- Orbital analysis and visualization, where applicable

## System Parameters

The baseline communication model uses the following parameters:

| Parameter | Value |
|---|---:|
| Carrier frequency | 2.2 GHz |
| Transmit power | 5 W |
| Transmit antenna gain | 3 dBi |
| Receiver antenna gain | 15 dBi |
| System losses | 2 dB |
| Bandwidth | 1 MHz |
| Noise figure | 3 dB |
| Required SNR | 6 dB |

## Methodology

1. Define the satellite communication system parameters.
2. Calculate free-space path loss over a range of satellite distances.
3. Estimate received power and SNR.
4. Calculate the link margin relative to the required SNR.
5. Compare antenna gain configurations to study potential performance improvements.

## Simulation Results

The MATLAB simulations investigate how communication range affects link performance and how receiver antenna gain can improve the link margin.

Simulation plots, comparison tables, and numerical results will be included in the `results/` directory.

## Repository Contents

- `ASTRA_Communication.m` — Communication link analysis.
- `ASTRA_Orbit.m` — Orbital analysis, if included.
- `ASTRA_Integrated.m` — Integrated simulation, if included.
- `results/` — Simulation plots and screenshots.
- `report/` — Project report, if included.

## Future Improvements

- Refine the satellite orbit and visibility model.
- Incorporate more realistic propagation and system losses.
- Optimize antenna parameters for improved link margin.
- Validate the simulated results against additional system scenarios.


## Acknowledgment

This project was developed collaboratively by a three-member team as part of the SPACEFORGE satellite design and simulation challenge.
