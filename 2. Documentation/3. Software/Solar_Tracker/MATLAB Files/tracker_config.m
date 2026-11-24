function cfg = tracker_config()
%TRACKER_CONFIG  EDIT THESE INPUTS TO MATCH THE ACTUAL CAPSTONE HARDWARE.
% Coordinate system attached to the lower frame: x=East, y=North, z=Up.
% Lengths in meters; angles in radians; power in watts.
%
% IMPORTANT: Motor hardware has NOT been selected for this geometry.
% Mount coordinates are a geometric model. Actuator travel and speed
% below are VIRTUAL design targets, not tested physical hardware.
% Real equipment, force, current, weather and holding safety are unverified.

% Panel / frame design assumption: 48 in East-West by 68 in North-South.
% Swap these values if the long edge actually runs East-West. Geometry must
% be replaced with measured frame dimensions before hardware sign-off.
cfg.panelEW = 48 * 0.0254;
cfg.panelNS = 68 * 0.0254;
cfg.panelArea = cfg.panelEW * cfg.panelNS;
cfg.panelEfficiency = 0.205;       % illustrative, NOT measured

% Z = 0: bottom frame plane.  Z = 12 in: upper frame plane (when level).
% Ball-joint center sits halfway: 6 in above base, 6 in below top frame.
cfg.frameSeparation = 12 * 0.0254;
cfg.upperPlaneOffset = 6 * 0.0254;  % upper-frame Z relative to pivot
cfg.pivot = [0; 0; 6 * 0.0254];
% Retained for future force/energy modeling; not used by this kinematic demo.
cfg.upperAssemblyWeightLbf = 55; 
cfg.cgHeightAbovePivotM = 6 * 0.0254;

% OUTER-RIM MIDPOINT LAYOUT (v2.2): x=East, y=North, z=Up.
% Each actuator's LOWER pivot is on the outside rim of the fixed frame,
% directly under its UPPER pivot when the moving panel is horizontal.
% No internal mounting cross-bars or inward mounting offsets are used.
%
% Columns: [NORTH actuator, WEST actuator]
%   North lower = (0,+34,0) in; north upper = (0,+34,12) in when level
%   West lower  = (-24,0,0) in; west upper  = (-24,0,12) in when level
% Upper positions are relative to the central ball joint, at z=+6 in.
in = 0.0254;
cfg.lowerMounts = in * [  0, -24;
                         +34,   0;
                           0,   0];
cfg.upperMounts = in * [  0, -24;
                         +34,   0;
                          +6,  +6];
cfg.lowerMountRadialSetbackIn = 0;

% Two articulated elbow supports on OPPOSITE upper-panel edge midpoints.
% Column 1: South elbow, column 2: East elbow.
% These consist of two equal, freely hinged 10-inch links per assembly.
% Lower anchors sit on the lower-frame rim; upper anchors on top-frame rim.
% The elbow knees fold in a convenient out-of-line direction for plotting.
% These idealized joints CONSTRAIN MAXIMUM REACH ONLY. Freely folding two-
% link supports do NOT establish yaw/torsional stability or resist arbitrary
% static loads without additional linkage design. No arm-arm collision
% checking or joint force model is currently implemented.
cfg.elbowNames = {'South','East'};
cfg.elbowLowerMounts = in * [  0, +24;
                                -34,   0;
                                  0,   0];
cfg.elbowUpperMounts = in * [  0, +24;
                                -34,   0;
                                 +6,  +6];
cfg.elbowLinkLength = [10;10] * in;  % length of EACH segment
cfg.elbowKneeSide = [1,0;0,1;0,0];  % preferred knee bend directions

% REQUIRED PIN-TO-PIN ENVELOPE FROM EXACT 3D GEOMETRY (±8 deg both axes):
%   North: 7.2175 to 16.7142 in (required travel  9.4967 in)
%   West:  8.6048 to 15.3191 in (required travel  6.7143 in)
%
% VIRTUAL ACTUATOR ENVELOPES, with ~0.7–0.9 inch end margins.
% THESE ARE NOT A SELECTED OR VERIFIED COMMERCIALLY AVAILABLE PRODUCT.
% In particular, a rod-style actuator with <=6.5" fully retracted
% length AND >=11" stroke is not realistic for a conventional single-
% stage design. This MATLAB model illustrates an IDEALIZED mechanism.
% A custom multistage mechanism or a linkage/frame redesign is needed for
% physical realization. DO NOT represent this as a procurement-ready BOM.
cfg.actuatorModel = 'VIRTUAL COMPACT EXTENDING MECHANISM - NOT SELECTED';
cfg.physicalActuatorSelected = false;
cfg.actMinLength = [6.50;7.75] * in; % north, west virtual retracted pin distance
cfg.actMaxLength = [17.50;16.00] * in; % north, west virtual max pin distance
cfg.actStrokeM = cfg.actMaxLength - cfg.actMinLength; % virtual strokes
cfg.actVoltageV = NaN;            % no selected motor or rated voltage
cfg.actRatedForceN = NaN;         % unknown until mechanism is selected
cfg.actMaxCurrentA = NaN;         % unknown; do not use prior Firgelli draw
cfg.actDutyFractionFullLoad = NaN;
cfg.actNoLoadSpeedMps = NaN;      % physical actuator not selected
cfg.actLoadSpeedFactor = NaN;
cfg.actSpeed = [0.30;0.30] * in;  % ILLUSTRATIVE travel speed, in/s
cfg.actRunPower = [NaN;NaN];      % no energy/power estimate available
% Virtual positions are known exactly in simulation; real hardware needs
% absolute position feedback and mechanical travel interlocks.
cfg.idealVirtualPositionSensor = true;

% -----------------------------------------------------------------------
% v2.0 QUASI-STATIC FORCE + ILLUSTRATIVE CURRENT MODEL
% -----------------------------------------------------------------------
% Force is computed from actual actuator line-of-action geometry and
% weight/CG by solving two moment-equilibrium equations. No actuator
% product is selected for these virtual compact actuators.
%
% NO VALID ACTUAL CURRENT CAN BE CALCULATED FROM FORCE ALONE.
% Example below uses an illustrative no-load current, supply, mechanical
% drive efficiency, and the simulated actual actuator speed. These are
% editable ASSUMPTIONS and NOT a motor specification or measurement.
cfg.assumedMotorVoltageV = 12.0;           % assumed motor terminal voltage
cfg.assumedNoLoadCurrentA = [1.0;1.0];  % assumed ON-state current (not measured)
cfg.assumedDriveEfficiency = 0.35;      % motor + gearbox + screw, hypothetical
cfg.assumedDCDCefficiency = 0.90;       % battery-to-motor conversion
% Illustrative transient above running current when the motor STARTS.
% The average transient contribution lasts at most startDurationSec;
% the STEP graph shows current AVERAGED over each simulation interval.
cfg.assumedStartExtraCurrentA = [1.5;1.5]; % extra amps at startup (assumed)
cfg.assumedStartDurationSec = 0.08;       % assumed startup transient, seconds
% Unpowered motors use zero electrical holding current. Mechanical holding
% against backdriving is NOT verified. Only use a nonzero value if a
% selected driver maintains active electrical holding after stopping.
cfg.assumedHoldCurrentA = [0;0];
% While moving, illustrative load contribution is |F*v|/(efficiency*V).
% No real part has been selected. Friction, motor winding characteristics,
% acceleration and regenerative operation remain unknown. Values are
% a SENSITIVITY SCENARIO, not engineering predictions.


cfg.maxPitchDeg = 8;              % requested initial limit, NOT CAD-verified
cfg.maxRollDeg = 8;
cfg.minPanelHeight = 0.05;        % illustrative 50 mm clearance above lower plane

cfg.latitudeDeg = 36.2;            % ILLUSTRATIVE latitude; adjust for location
cfg.dayOfYear = 172;               % illustrative June day
cfg.startSolarHour = 8;
cfg.endSolarHour = 17;
cfg.samplePeriodSec = 45;
cfg.probeStepDeg = 2;              % power-search command increment
cfg.probeThresholdW = 0.35;        % minimum power increase to accept trial
cfg.measureNoiseStdW = 0;         % start noise-free; increase in stress tests

% Simplified hypothetical clear-day weather, NOT historic observed weather.
cfg.peakDNI = 850;                 % W/m^2 direct-normal irradiance
cfg.peakDHI = 120;                 % W/m^2 diffuse-horizontal irradiance
cfg.albedo = 0.20;
cfg.cloudStartSolarHour = 12.25;
cfg.cloudEndSolarHour = 13.00;
cfg.cloudFactor = 1.0;            % 1 = clear day; try 0.35 for cloud event
end
