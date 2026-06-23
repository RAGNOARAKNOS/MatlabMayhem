function create_pelican()
%CREATE_PELICAN  Day 2: a Pelican crossing driven by a pedestrian push button.
%
%   Builds model Pelican.slx with a Stateflow chart "PelicanCrossing". The
%   vehicle light sits on GREEN until a pedestrian presses the button. The
%   press is *latched* (so a quick tap is never missed) and *serviced safely*
%   -- the lights only change after a minimum green time, never mid-phase:
%
%       VEH_GREEN --[req & min green]--> VEH_AMBER --> VEH_RED (all-red)
%         --> PED_WALK (steady green man) --> PED_FLASH (flashing amber +
%         flashing green man, clears request) --> VEH_GREEN ...
%
%   New ideas vs Day 1: an INPUT (the button), a GUARD/condition on a
%   transition, a LATCHED request, a minimum-time safety constraint, and a
%   FLASHING lamp (a lamp toggled over time inside a state).
%
%   Run it with:  create_pelican;  run_demo('Pelican')
%   Then double-click the "Press" switch while it runs to request a crossing.
%
%   Idempotent: re-running rebuilds the model from scratch.

    H     = tl_helpers();
    model = 'Pelican';
    chart = H.newChartModel(model, 'PelicanCrossing');

    % --- input: the pedestrian button (0/1), driven by a Manual Switch ------
    H.mkData(chart, 'request', 'Input', 'boolean');

    % --- outputs: vehicle lamps then pedestrian lamps (order = port order) --
    H.mkData(chart, 'veh_red',   'Output');
    H.mkData(chart, 'veh_amber', 'Output');
    H.mkData(chart, 'veh_green', 'Output');
    H.mkData(chart, 'ped_red',   'Output');
    H.mkData(chart, 'ped_green', 'Output');

    % --- local: the latched request flag (starts cleared) -------------------
    H.mkData(chart, 'req', 'Local', 'boolean', 'false');
    % counter used to make the amber flash (toggles every few time steps)
    H.mkData(chart, 'blink', 'Local', 'double', '0');

    % Helper to write all five lamps in one entry action, e.g. lamps(1,1,0, 1,0)
    lamps = @(vr,va,vg,pr,pg) sprintf( ...
        'en: veh_red=%d; veh_amber=%d; veh_green=%d; ped_red=%d; ped_green=%d;', ...
        vr, va, vg, pr, pg);

    % --- states -------------------------------------------------------------
    % Cars go, pedestrians wait. While here, latch any button press into req.
    GREEN = H.mkState(chart, ['VEH_GREEN\n' lamps(0,0,1, 1,0) ...
                              '\ndu: if request; req = true; end'], [ 60  60 240 90]);
    AMBER = H.mkState(chart, ['VEH_AMBER\n'    lamps(0,1,0, 1,0)], [380  60 240 70]);
    REDA  = H.mkState(chart, ['VEH_RED\n'      lamps(1,0,0, 1,0)], [380 220 240 70]);
    WALK  = H.mkState(chart, ['PED_WALK\n'     lamps(1,0,0, 0,1)], [380 380 240 70]);
    % FLASHING AMBER: the UK Pelican hand-back phase. Cars get a *flashing*
    % amber (give way to anyone still crossing) and the green man *flashes*.
    % A state can make a lamp flash by toggling it on a counter in its "during"
    % action -- this is itself a tiny state machine (on/off/on/off...).
    % Note: a real Pelican goes flashing-amber -> green (NO red+amber), which
    % is different from a junction or a Puffin crossing. Requirements differ
    % per system -- a good thing to point out to the student.
    FLASH = H.mkState(chart, ['PED_FLASH\n' ...
        'en: veh_red=0; veh_amber=1; veh_green=0; ped_red=0; ped_green=1; req=false; blink=0;\n' ...
        'du: blink=blink+1; if blink>=5; veh_amber=1-veh_amber; ped_green=1-ped_green; blink=0; end'], ...
        [ 60 300 280 110]);

    % --- a crossing always starts with cars flowing -------------------------
    H.mkDefault(chart, GREEN);

    % --- transitions --------------------------------------------------------
    % Leave green only when a request is latched AND minimum green has elapsed.
    H.mkTrans(chart, GREEN, AMBER, '[req && after(5,sec)]');
    H.mkTrans(chart, AMBER, REDA,  'after(3,sec)');
    H.mkTrans(chart, REDA,  WALK,  'after(1,sec)');   % all-red clearance
    H.mkTrans(chart, WALK,  FLASH, 'after(6,sec)');   % steady green man -> flashing
    H.mkTrans(chart, FLASH, GREEN, 'after(5,sec)');   % flashing amber -> cars go

    % --- harness: button input + lamp logging -------------------------------
    H.addManualInput(model, 'PelicanCrossing', 1);
    H.addOutputLogging(model, 'PelicanCrossing', ...
        {'veh_red', 'veh_amber', 'veh_green', 'ped_red', 'ped_green'});
    H.configDiscrete(model, 60);

    % --- visual: a vehicle head (R/A/G) beside a pedestrian head (R/G) ------
    C = H.colors;
    heads = { {[700 40], [1 2 3], [C.red; C.amber; C.green]}, ...   % vehicles
              {[820 40], [4 5],   [C.red; C.green]} };               % pedestrians
    H.finish(model, chart, heads);
end
