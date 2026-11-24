function x_sensor_tracker_demo()
%X_SENSOR_TRACKER_DEMO Interactive 3D digital twin of X-sensor solar tracker.
%
% Run in MATLAB Command Window:
%     x_sensor_tracker_demo
%
% Enter sun azimuth (0=N, 90=E, 180=S, 270=W) and elevation (60..90).
% Sun may be at most 30 degrees from directly overhead in ANY direction.
% Press RUN, STEP, PAUSE, or RESET. Change sun inputs while running.
% The controller sees ONLY the four simulated sunlight sensor readings.
%
% Requires BASE MATLAB and x_sensor_core.m + tracker_config.m in folder.
% v2.1: N/W actuators mounted on BOTH fixed and moving frame outer edge
% midpoints; modeled compact actuators are virtual, not selected hardware.
% This is a preliminary kinematic demonstration, not hardware validation.

% Explicit high-contrast UI colors. MATLAB/Windows dark themes can otherwise
% render near-white top controls on a nearly white figure background.
uiText=[.08 .14 .22];
uiBg=[.98 .99 1];
uiStatusBg=[.88 .93 .98];
uiButtonBg=[.88 .92 .97];
uiRunBg=[.75 .91 .80];

% User-requested sky range. Sun zenith is elevation=90 deg.
% A 30 deg maximum deviation from zenith means elevation >= 60 deg.
maxSunOffsetFromZenithDeg=30;
minSunElevationDeg=90-maxSunOffsetFromZenithDeg;

% RUN DURATION: change this one value to set the simulation time limit.
% Each controller step adds cfg.demoDtSeconds (0.20 s by default).
% For example, 15, 30, or 60 seconds. This is SIMULATED time, not wall time.
maxSimSeconds = 30;

% Real-world spacing between visual updates. Larger = slower animation.
uiTickPeriodSeconds = 0.12;

cfg=x_sensor_core('config');
st=x_sensor_core('init',cfg);
initialAz=315;
initialEl=82;
st.sensor=x_sensor_core('sense',st.angles,initialAz,initialEl,cfg);

fig=figure('Name','Solar Tracker | X-sensor, VIRTUAL edge-mounted actuators', ...
    'NumberTitle','off','Color',uiBg, ...
    'Position',[70 65 1330 820],'MenuBar','none', ...
    'ToolBar','figure','CloseRequestFcn',@closeDemo);
setappdata(fig,'running',false);
setappdata(fig,'state',st);

% ------------------------------------------------------------------
% Top: user-selected SUN LOCATION. Values are plant inputs, NOT
% controller targets: the tracking code never reads these values.
% ------------------------------------------------------------------
uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[.02 .948 .074 .029],'String','Azimuth (deg)', ...
    'BackgroundColor',uiBg,'ForegroundColor',uiText, ...
    'FontSize',10,'FontWeight','bold','HorizontalAlignment','left');
hAz=uicontrol(fig,'Style','slider','Units','normalized', ...
    'Position',[.105 .949 .165 .026],'Min',0,'Max',360, ...
    'Value',initialAz,'Callback',@sliderChanged);
hAzEdit=uicontrol(fig,'Style','edit','Units','normalized', ...
    'Position',[.273 .945 .044 .032],'String',num2str(initialAz), ...
    'Callback',@editChanged,'BackgroundColor','w', ...
    'ForegroundColor',uiText,'FontWeight','bold');
uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[.334 .948 .096 .029],'String','Elevation (deg)', ...
    'BackgroundColor',uiBg,'ForegroundColor',uiText, ...
    'FontSize',10,'FontWeight','bold','HorizontalAlignment','left');
hEl=uicontrol(fig,'Style','slider','Units','normalized', ...
    'Position',[.434 .949 .151 .026],'Min',minSunElevationDeg,'Max',90, ...
    'Value',initialEl,'Callback',@sliderChanged);
hElEdit=uicontrol(fig,'Style','edit','Units','normalized', ...
    'Position',[.590 .945 .042 .032],'String',num2str(initialEl), ...
    'Callback',@editChanged,'BackgroundColor','w', ...
    'ForegroundColor',uiText,'FontWeight','bold');
uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[.651 .944 .09 .031],'String','Sun presets', ...
    'BackgroundColor',uiBg,'ForegroundColor',uiText, ...
    'FontSize',10,'FontWeight','bold','HorizontalAlignment','right');
hPreset=uicontrol(fig,'Style','popupmenu','Units','normalized', ...
    'Position',[.749 .943 .226 .035], ...
    'String',{'Northwest, near zenith (315, 82)', ...
              'Northeast, near zenith (45, 82)', ...
              'East, near zenith (90, 82)', ...
              'South, near zenith (180, 82)', ...
              'Directly overhead (0, 90)', ...
              'Northwest, 30 deg off overhead (315, 60)', ...
              'Southeast, 30 deg off overhead (135, 60)'}, ...
    'Callback',@choosePreset,'BackgroundColor','w', ...
    'ForegroundColor',uiText);

hRun=uicontrol(fig,'Style','pushbutton','Units','normalized', ...
    'Position',[.024 .888 .094 .042],'String','RUN / RESUME', ...
    'FontWeight','bold','ForegroundColor',uiText, ...
    'Callback',@runDemo,'BackgroundColor',uiRunBg);
hPause=uicontrol(fig,'Style','pushbutton','Units','normalized', ...
    'Position',[.130 .888 .086 .042],'String','PAUSE', ...
    'Callback',@pauseDemo, ...
    'BackgroundColor',uiButtonBg,'ForegroundColor',uiText, ...
    'FontWeight','bold');
hStep=uicontrol(fig,'Style','pushbutton','Units','normalized', ...
    'Position',[.225 .888 .086 .042],'String','STEP', ...
    'Callback',@oneStep, ...
    'BackgroundColor',uiButtonBg,'ForegroundColor',uiText, ...
    'FontWeight','bold');
hReset=uicontrol(fig,'Style','pushbutton','Units','normalized', ...
    'Position',[.319 .888 .086 .042],'String','RESET', ...
    'Callback',@resetDemo, ...
    'BackgroundColor',uiButtonBg,'ForegroundColor',uiText, ...
    'FontWeight','bold');
hExport=uicontrol(fig,'Style','pushbutton','Units','normalized', ...
    'Position',[.414 .888 .084 .042],'String','EXPORT CSV', ...
    'Callback',@exportCSV, ...
    'BackgroundColor',uiButtonBg,'ForegroundColor',uiText, ...
    'FontWeight','bold');
hStatus=uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[.510 .824 .47 .111], ...
    'String','Ready - press RUN','HorizontalAlignment','left', ...
    'BackgroundColor',uiStatusBg,'ForegroundColor',uiText, ...
    'FontSize',9,'FontWeight','bold');

% ------------------------------------------------------------------
% 3D scene: centered N/W actuators, hinged S/E support arms, center ball.
% ------------------------------------------------------------------
ax3=axes('Parent',fig,'Units','normalized', ...
    'Position',[.037 .275 .558 .550]);
hold(ax3,'on'); grid(ax3,'on');
axis(ax3,[-50 50 -65 65 -5 69]); axis(ax3,'vis3d');
view(ax3,-38,25);
set(ax3,'XDir','normal','YDir','normal');
xlabel(ax3,'East / West (in)');
ylabel(ax3,'North / South (in)');
zlabel(ax3,'Height (in)');
title(ax3,'Outer-rim N/W mounts | virtual actuators | S/E elbows');
baseX=[-22 22 22 -22]*.0254;
baseY=[-36 -36 36 36]*.0254;
baseZ=zeros(1,4);
patch(ax3,baseX/.0254,baseY/.0254,baseZ, ...
    [.63 .68 .75],'FaceAlpha',.08,'EdgeColor',[.37 .43 .50], ...
    'LineWidth',2.3);
% Actuator lower pins mount directly at N/W midpoints of the perimeter.
% No interior cross-bracing is drawn or required by this IDEALIZED layout.
hTop=patch(ax3,nan(1,4),nan(1,4),nan(1,4),[.18 .47 .85], ...
    'FaceAlpha',.48,'EdgeColor',[.05 .22 .53],'LineWidth',2.2);
hBall=scatter3(ax3,0,0,6,115,[.98 .73 .16],'filled', ...
    'MarkerEdgeColor',[.55 .35 0]);
% Show rotating central support with two stems meeting at the ball.
plot3(ax3,[0 0],[0 0],[0 6],'-','Color',[.46 .51 .58],'LineWidth',3);
hPivotTop=plot3(ax3,nan,nan,nan,'-','Color',[.46 .51 .58],'LineWidth',3);
colors={[.02 .54 .47],[.94 .53 .12]};
actuatorNames={'North','West'};
hAct=gobjects(2,1);hActBase=gobjects(2,1);hActTip=gobjects(2,1);
for i=1:2
    hAct(i)=plot3(ax3,nan,nan,nan,'-','LineWidth',7,'Color',colors{i});
    hActBase(i)=plot3(ax3,nan,nan,nan,'o','Color',colors{i}, ...
        'MarkerFaceColor',colors{i},'MarkerSize',7);
    hActTip(i)=plot3(ax3,nan,nan,nan,'o','Color',colors{i}, ...
        'MarkerFaceColor',colors{i},'MarkerSize',7);
end
% Opposite-edge, double-link elbow supports: South (violet), East (red).
% Each support is rendered with two rigid links and a moving central hinge.
elbowColors={[.62 .33 .80],[.86 .28 .34]};
hElbowLower=gobjects(2,1);hElbowUpper=gobjects(2,1);
hElbowKnee=gobjects(2,1);hElbowAnchor=gobjects(2,1);
for ii=1:2
    c=elbowColors{ii};
    hElbowLower(ii)=plot3(ax3,nan,nan,nan,'-', ...
        'LineWidth',4,'Color',c);
    hElbowUpper(ii)=plot3(ax3,nan,nan,nan,'-', ...
        'LineWidth',4,'Color',c);
    hElbowKnee(ii)=plot3(ax3,nan,nan,nan,'o', ...
        'MarkerFaceColor',c,'MarkerEdgeColor',[.15 .15 .2], ...
        'MarkerSize',8);
    hElbowAnchor(ii)=plot3(ax3,nan,nan,nan,'s', ...
        'MarkerFaceColor',c,'MarkerEdgeColor',[.15 .15 .2], ...
        'MarkerSize',6);
end
hNormal=quiver3(ax3,0,0,0,0,0,1,0,'Color',[.09 .34 .73], ...
    'LineWidth',2,'MaxHeadSize',.8);
hSun=quiver3(ax3,0,0,0,0,0,1,0,'Color',[.95 .64 .08], ...
    'LineWidth',3,'MaxHeadSize',.9);
% X sensor walls drawn on panel, and four photosensors around intersection.
hWall1=plot3(ax3,nan,nan,nan,'-','LineWidth',3,'Color',[.12 .16 .21]);
hWall2=plot3(ax3,nan,nan,nan,'-','LineWidth',3,'Color',[.12 .16 .21]);
hDots=gobjects(4,1);
for j=1:4
    hDots(j)=plot3(ax3,nan,nan,nan,'o','MarkerFaceColor',[1 .8 .1], ...
        'MarkerEdgeColor',[.4 .3 0],'MarkerSize',6);
end
text(ax3,34,50,0,'N','FontWeight','bold');
text(ax3,43,-36,0,'E','FontWeight','bold');

% ------------------------------------------------------------------
% Top-right: actual geometry of diagonal walls and sensor patch colors.
% ------------------------------------------------------------------
axSensor=axes('Parent',fig,'Units','normalized', ...
    'Position',[.672 .560 .288 .255]);
hold(axSensor,'on'); axis(axSensor,'equal');
axis(axSensor,[-.08 .08 -.117 .117]);
set(axSensor,'XTick',[],'YTick',[],'Box','on');
title(axSensor,'X-shaped sensor (top view)','Color',uiText,'FontWeight','bold');
rectangle('Parent',axSensor,'Position',[-.06,-.098,.12,.196], ...
    'EdgeColor',[.2 .35 .6],'LineWidth',1.8);
u1=[cfg.panelEW/2;cfg.panelNS/2];u1=u1/norm(u1);
u2=[-cfg.panelEW/2;cfg.panelNS/2];u2=u2/norm(u2);
plot(axSensor,[-u1(1),u1(1)]*.115,[-u1(2),u1(2)]*.115, ...
    '-','LineWidth',6,'Color',[.21 .25 .31]);
plot(axSensor,[-u2(1),u2(1)]*.115,[-u2(2),u2(2)]*.115, ...
    '-','LineWidth',6,'Color',[.21 .25 .31]);
centers=[0,cfg.sensorEastOffset,0,-cfg.sensorEastOffset; ...
         cfg.sensorNorthOffset,0,-cfg.sensorNorthOffset,0];
labels={'N','E','S','W'};
hSpheres=gobjects(4,1);
for j=1:4
    c=centers(:,j);
    hSpheres(j)=rectangle('Parent',axSensor, ...
        'Position',[c(1)-cfg.sensorRadius,c(2)-cfg.sensorRadius, ...
        2*cfg.sensorRadius,2*cfg.sensorRadius], ...
        'Curvature',[1 1],'LineWidth',.8, ...
        'EdgeColor',[.55 .38 .07],'FaceColor',[.98 .82 .13]);
    switch j
        case 1, off=[0 .013];
        case 2, off=[.015 0];
        case 3, off=[0 -.013];
        otherwise, off=[-.015 0];
    end
    text(axSensor,c(1)+off(1),c(2)+off(2),labels{j}, ...
        'FontWeight','bold','HorizontalAlignment','center','FontSize',10);
end

% Four sensor readings as bars with consistent N/E/S/W ordering.
axBars=axes('Parent',fig,'Units','normalized', ...
    'Position',[.665 .295 .295 .214]);
hBars=bar(axBars,1:4,zeros(1,4),.66,'FaceColor',[.95 .72 .12]);
set(axBars,'XTick',1:4,'XTickLabel',labels);
ylim(axBars,[0 1000]);ylabel(axBars,'Simulated signal','Color',uiText);
title(axBars,'Photocell measurements','Color',uiText,'FontWeight','bold');grid(axBars,'on');

% Bottom row of three time histories: sensor errors, actuator FORCE,
% and assumed STEP-AVERAGED CURRENT, with hypothetical start transients.
% Peak samples are dotted (not measured sensor values).
axHistory=axes('Parent',fig,'Units','normalized', ...
    'Position',[.055 .086 .252 .135]);
hNS=plot(axHistory,0,0,'-','Color',[.04 .55 .47], ...
    'LineWidth',1.6);hold(axHistory,'on');
hEW=plot(axHistory,0,0,'-','Color',[.88 .49 .10], ...
    'LineWidth',1.6);
xlabel(axHistory,'Time (s)','Color',uiText);
ylabel(axHistory,'Error','Color',uiText);
title(axHistory,'Sensor imbalance','Color',uiText);
legend(axHistory,{'N-S','W-E'},'Location','northeast','FontSize',7);
grid(axHistory,'on');

axForce=axes('Parent',fig,'Units','normalized', ...
    'Position',[.391 .086 .235 .135]);
hForceN=plot(axForce,0,0,'-','Color',[.04 .55 .47], ...
    'LineWidth',1.7);hold(axForce,'on');
hForceW=plot(axForce,0,0,'-','Color',[.88 .49 .10], ...
    'LineWidth',1.7);
xlabel(axForce,'Time (s)','Color',uiText);
ylabel(axForce,'Axial force (lbf)','Color',uiText);
title(axForce,'Gravity-only force (signed)','Color',uiText);
legend(axForce,{'North','West'},'Location','northeast','FontSize',7);
grid(axForce,'on');

axCurrent=axes('Parent',fig,'Units','normalized', ...
    'Position',[.719 .086 .236 .135]);
hCurrentN=plot(axCurrent,0,0,'-','Color',[.04 .55 .47], ...
    'LineWidth',1.7);hold(axCurrent,'on');
hCurrentW=plot(axCurrent,0,0,'-','Color',[.88 .49 .10], ...
    'LineWidth',1.7);
hCurrentNPeak=plot(axCurrent,0,0,':','Color',[.04 .55 .47], ...
    'LineWidth',1.0);
hCurrentWPeak=plot(axCurrent,0,0,':','Color',[.88 .49 .10], ...
    'LineWidth',1.0);
xlabel(axCurrent,'Time (s)','Color',uiText);
ylabel(axCurrent,'Motor current (A)','Color',uiText);
title(axCurrent,'Assumed current: mean + peak','Color',uiText);
legend(axCurrent,{'N mean','W mean','N peak','W peak'}, ...
    'Location','northeast','FontSize',6);
grid(axCurrent,'on');

% One short timer callback per controller step. Unlike a blocking while
% loop, this allows the PAUSE/RESET buttons to run between steps.
simTimer = timer('ExecutionMode','fixedSpacing', ...
    'Period',uiTickPeriodSeconds,'TimerFcn',@runTick);

updateDisplay();

% -------------------- GUI callbacks ----------------------------------
    function sliderChanged(~,~)
        set(hAzEdit,'String',sprintf('%.0f',get(hAz,'Value')));
        set(hElEdit,'String',sprintf('%.0f',get(hEl,'Value')));
        updateDisplay();
    end

    function editChanged(~,~)
        a=str2double(get(hAzEdit,'String'));
        e=str2double(get(hElEdit,'String'));
        if ~isfinite(a),a=get(hAz,'Value');end
        if ~isfinite(e),e=get(hEl,'Value');end
        a=mod(a,360); e=max(minSunElevationDeg,min(90,e));
        setSun(a,e);
    end

    function choosePreset(~,~)
        vals=[315,82;45,82;90,82;180,82;0,90;315,60;135,60];
        v=vals(get(hPreset,'Value'),:);
        setSun(v(1),v(2));
    end

    function setSun(a,e)
        e=max(minSunElevationDeg,min(90,e));
        set(hAz,'Value',a);set(hEl,'Value',e);
        set(hAzEdit,'String',sprintf('%.1f',a));
        set(hElEdit,'String',sprintf('%.1f',e));
        updateDisplay();
        drawnow limitrate;
    end

    function [az,el]=currentSun()
        az=get(hAz,'Value');el=get(hEl,'Value');
    end

    function runDemo(~,~)
        if ~ishandle(fig) || getappdata(fig,'running'), return; end
        s = getappdata(fig,'state');
        if s.t >= maxSimSeconds-1e-9
            set(hStatus,'String',sprintf( ...
                'Time limit reached (%.1f simulated s). Press RESET to run again.',maxSimSeconds));
            return;
        end
        setappdata(fig,'running',true);
        set(hRun,'String','RUNNING','BackgroundColor',uiButtonBg);
        try
            start(simTimer);
        catch ME
            setappdata(fig,'running',false);
            set(hRun,'String','RUN / RESUME','BackgroundColor',uiRunBg);
            set(hStatus,'String',sprintf('Unable to start simulation: %s', ME.message));
        end
    end

    function runTick(~,~)
        if ~ishandle(fig) || ~getappdata(fig,'running'), return; end
        try
            s = getappdata(fig,'state');
            if s.t >= maxSimSeconds-1e-9
                stopRun(sprintf('Time limit reached (%.1f simulated s). Press RESET to run again.',maxSimSeconds));
                return;
            end
            advance();
            drawnow limitrate;
            s = getappdata(fig,'state');
            if s.t >= maxSimSeconds-1e-9
                stopRun(sprintf('Time limit reached (%.1f simulated s). Press RESET to run again.',maxSimSeconds));
            end
        catch ME
            stopRun(sprintf('Simulation stopped: %s',ME.message));
            warning('XSensorTwin:RunError','%s',getReport(ME,'basic'));
        end
    end

    function stopRun(reason)
        if ~ishandle(fig), return; end
        setappdata(fig,'running',false);
        if isvalid(simTimer) && strcmp(simTimer.Running,'on')
            stop(simTimer);
        end
        set(hRun,'String','RUN / RESUME','BackgroundColor',uiRunBg);
        if nargin>0 && ~isempty(reason)
            set(hStatus,'String',reason);
        end
    end

    function pauseDemo(~,~)
        if ishandle(fig)
            s = getappdata(fig,'state');
            stopRun(sprintf('Paused at %.1f simulated s. Press RUN to resume.',s.t));
        end
    end

    function oneStep(~,~)
        if ~ishandle(fig) || getappdata(fig,'running'), return; end
        s = getappdata(fig,'state');
        if s.t >= maxSimSeconds-1e-9
            set(hStatus,'String',sprintf( ...
                'Time limit reached (%.1f simulated s). Press RESET to run again.',maxSimSeconds));
            return;
        end
        advance();
        drawnow;
        s = getappdata(fig,'state');
        if s.t >= maxSimSeconds-1e-9
            set(hStatus,'String',sprintf( ...
                'Time limit reached (%.1f simulated s). Press RESET to run again.',maxSimSeconds));
        end
    end

    function resetDemo(~,~)
        stopRun('');
        newSt=x_sensor_core('init',cfg);
        setappdata(fig,'state',newSt);
        updateDisplay();
    end

    function exportCSV(~,~)
        s=getappdata(fig,'state');
        h=s.hist;
        [f,p]=uiputfile('x_sensor_tracking_run.csv','Export simulation data');
        if isequal(f,0),return;end
        [az,el]=currentSun();
        T=table(h.t(:),h.N(:),h.E(:),h.S(:),h.W(:), ...
            h.errorNS(:),h.errorEW(:),h.pitch(:),h.roll(:), ...
            h.northLengthIn(:),h.westLengthIn(:),h.align(:), ...
            h.sunAzDeg(:),h.sunElevDeg(:), ...
            h.northForceLbf(:),h.westForceLbf(:), ...
            h.northCurrentA(:),h.westCurrentA(:), ...
            h.northCurrentPeakA(:),h.westCurrentPeakA(:), ...
            h.northLoadAddedMilliA(:),h.westLoadAddedMilliA(:), ...
            h.northStartAddedA(:),h.westStartAddedA(:), ...
            h.northMotorDuty(:),h.westMotorDuty(:), ...
            h.batteryEnergyWh(:),h.yawResidualNm(:), ...
            'VariableNames',{'timeSec','sensorN','sensorE','sensorS', ...
            'sensorW','errorNS','errorWE','northEdgeUpDeg', ...
            'westEdgeUpDeg','northActuatorLengthIn','westActuatorLengthIn', ...
            'truePointingErrorDeg','sunAzimuthDeg','sunElevationDeg', ...
            'northAxialForceLbf','westAxialForceLbf', ...
            'northStepAverageCurrentA','westStepAverageCurrentA', ...
            'northIllustrativePeakA','westIllustrativePeakA', ...
            'northGravityLoadAddedMilliA','westGravityLoadAddedMilliA', ...
            'northStartupAddedAvgA','westStartupAddedAvgA', ...
            'northMotionDuty','westMotionDuty', ...
            'estimatedBatteryEnergyWh','unbalancedYawMomentNm'});
        writetable(T,fullfile(p,f));
        fprintf('Saved %d samples to %s\n',height(T),fullfile(p,f));
        fprintf('Current display sun: azimuth %.1f deg, elevation %.1f deg\n',az,el);
    end

    function closeDemo(~,~)
        setappdata(fig,'running',false);
        if isvalid(simTimer)
            if strcmp(simTimer.Running,'on'), stop(simTimer); end
            delete(simTimer);
        end
        delete(fig);
    end

    function advance()
        [az,el]=currentSun();
        old=getappdata(fig,'state');
        dt=min(cfg.demoDtSeconds,maxSimSeconds-old.t);
        if dt <= 1e-9, return; end
        newSt=x_sensor_core('step',old,cfg,az,el,dt);
        setappdata(fig,'state',newSt);
        updateDisplay();
    end

    function updateDisplay()
        if ~ishandle(fig),return;end
        [az,el]=currentSun();
        s=getappdata(fig,'state');
        m=x_sensor_core('sense',s.angles,az,el,cfg);
        R=x_sensor_core('rotation',s.angles);
        piv=cfg.pivot;
        halfx=cfg.panelEW/2; halfy=cfg.panelNS/2;
        pLocal=[-halfx,halfx,halfx,-halfx; ...
                -halfy,-halfy,halfy,halfy; ...
                cfg.upperPlaneOffset*ones(1,4)];
        pWorld=piv+R*pLocal;
        set(hTop,'XData',pWorld(1,:)/.0254, ...
                 'YData',pWorld(2,:)/.0254, ...
                 'ZData',pWorld(3,:)/.0254);
        center=piv+R*[0;0;cfg.upperPlaneOffset];
        set(hPivotTop,'XData',[0 center(1)]/.0254, ...
                      'YData',[0 center(2)]/.0254, ...
                      'ZData',[6 center(3)/.0254]);
        for ii=1:2
            from=cfg.lowerMounts(:,ii);
            to=piv+R*cfg.upperMounts(:,ii);
            set(hAct(ii),'XData',[from(1) to(1)]/.0254, ...
                'YData',[from(2) to(2)]/.0254, ...
                'ZData',[from(3) to(3)]/.0254);
            set(hActBase(ii),'XData',from(1)/.0254, ...
                'YData',from(2)/.0254,'ZData',from(3)/.0254);
            set(hActTip(ii),'XData',to(1)/.0254, ...
                'YData',to(2)/.0254,'ZData',to(3)/.0254);
        end
        [elbowPoints,~]=x_sensor_core('elbows',s.angles,cfg);
        for ii=1:2
            pointsIn=elbowPoints(:,:,ii)/.0254;
            set(hElbowLower(ii),'XData',pointsIn(1,1:2), ...
                'YData',pointsIn(2,1:2),'ZData',pointsIn(3,1:2));
            set(hElbowUpper(ii),'XData',pointsIn(1,2:3), ...
                'YData',pointsIn(2,2:3),'ZData',pointsIn(3,2:3));
            set(hElbowKnee(ii),'XData',pointsIn(1,2), ...
                'YData',pointsIn(2,2),'ZData',pointsIn(3,2));
            set(hElbowAnchor(ii),'XData',pointsIn(1,[1 3]), ...
                'YData',pointsIn(2,[1 3]),'ZData',pointsIn(3,[1 3]));
        end
        cIn=center/.0254;
        normal=R*[0;0;1];
        sun=x_sensor_core('sunvec',az,el);
        set(hNormal,'XData',cIn(1),'YData',cIn(2),'ZData',cIn(3), ...
            'UData',normal(1)*30,'VData',normal(2)*30,'WData',normal(3)*30);
        set(hSun,'XData',cIn(1),'YData',cIn(2),'ZData',cIn(3), ...
            'UData',sun(1)*35,'VData',sun(2)*35,'WData',sun(3)*35);
        diags=[[-.055;-.090],[.055;.090],[-.055;.090],[.055;-.090]];
        % Exact wall bearing matches panel diagonals, visual length is scaled.
        for widx=1:2
            if widx==1, ab=diags(:,1:2);else,ab=diags(:,3:4);end
            wc=piv+R*[ab;ones(1,2)*(cfg.upperPlaneOffset+.005)];
            if widx==1, hw=hWall1;else,hw=hWall2;end
            set(hw,'XData',wc(1,:)/.0254,'YData',wc(2,:)/.0254, ...
                'ZData',wc(3,:)/.0254);
        end
        for j=1:4
            xyz=piv+R*[centers(:,j);cfg.upperPlaneOffset+.007];
            set(hDots(j),'XData',xyz(1)/.0254,'YData',xyz(2)/.0254, ...
                'ZData',xyz(3)/.0254);
            z=min(1,max(0,m.raw(j)/940));
            set(hSpheres(j),'FaceColor',[.16+.82*z,.22+.61*z,.28-.13*z]);
        end
        set(hBars,'YData',m.raw(:).');
        set(hNS,'XData',s.hist.t,'YData',s.hist.errorNS);
        set(hEW,'XData',s.hist.t,'YData',s.hist.errorEW);
        set(hForceN,'XData',s.hist.t,'YData',s.hist.northForceLbf);
        set(hForceW,'XData',s.hist.t,'YData',s.hist.westForceLbf);
        set(hCurrentN,'XData',s.hist.t,'YData',s.hist.northCurrentA);
        set(hCurrentW,'XData',s.hist.t,'YData',s.hist.westCurrentA);
        set(hCurrentNPeak,'XData',s.hist.t,'YData',s.hist.northCurrentPeakA);
        set(hCurrentWPeak,'XData',s.hist.t,'YData',s.hist.westCurrentPeakA);
        if s.t>0
            xlim(axHistory,[max(0,s.t-80),max(25,s.t+3)]);
        else
            xlim(axHistory,[0 25]);
        end
        xlim(axForce,xlim(axHistory));
        xlim(axCurrent,xlim(axHistory));
        fmax=max(0.5,max(abs([s.hist.northForceLbf(:);s.hist.westForceLbf(:)])));
        ylim(axForce,[-1.2*fmax,1.2*fmax]);
        imax=max(0.25,max([s.hist.northCurrentA(:); ...
                           s.hist.westCurrentA(:); ...
                           s.hist.northCurrentPeakA(:); ...
                           s.hist.westCurrentPeakA(:)]));
        ylim(axCurrent,[0,1.20*imax]);
        ylim(axHistory,[-1 1]);
        errNow=acosd(max(-1,min(1,dot(normal,sun))));
        title(ax3,sprintf('Sun: %.0f deg az, %.0f deg elev | Panel error: %.1f deg', ...
            az,el,errNow),'Color',uiText,'FontWeight','bold');
        currentL=s.lengths/.0254;
        mode=s.mode;
        status={sprintf('%s | Sim %.1f s | PITCH/ROLL LIMIT: +/-8 deg',mode,s.t), ...
            sprintf('Tilt: pitch %.2f deg, roll %.2f deg | Actuators N %.2f in, W %.2f in', ...
                rad2deg(s.angles(1)),rad2deg(s.angles(2)),currentL(1),currentL(2)), ...
            sprintf('Sensor errors: N-S %+.3f, W-E %+.3f',m.error(1),m.error(2)), ...
            sprintf('Gravity axial forces: North %+.2f lbf | West %+.2f lbf', ...
                s.load.forceLbf(1),s.load.forceLbf(2)), ...
            sprintf('Assumed mean current: North %.3f A | West %.3f A', ...
                s.currentA(1),s.currentA(2)), ...
            sprintf('Load add: N %.1f mA, W %.1f mA | Battery energy %.5f Wh', ...
                1000*s.loadCurrentContributionA(1), ...
                1000*s.loadCurrentContributionA(2),s.batteryEnergyWh)};
        set(hStatus,'String',status);
        % 'True pointing error' is display-only: the feedback controller
        % NEVER uses this diagnostic to command any actuator.
    end
end
