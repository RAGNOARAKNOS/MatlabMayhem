function create_junction_4way()
%CREATE_JUNCTION_4WAY  Day 3 stretch: a sensor-actuated junction.
%
%   Builds model Junction4Way.slx with a Stateflow chart "Junction4Way". It
%   is the Day-3 junction made smarter: each approach has a vehicle SENSOR
%   (ns_demand / ew_demand). The controller only gives an approach green when
%   a car is actually waiting, and it serves the *other* approach next if a
%   car is waiting there -- so an empty road never holds up a busy one.
%
%       IDLE (all red, waiting)
%         -[ns_demand]->  NS phase  -> if ew waiting, serve EW next, else IDLE
%         -[ew_demand]->  EW phase  -> if ns waiting, serve NS next, else IDLE
%
%   It also has a NIGHT / FAULT mode (the "night" switch): every approach
%   flashes amber together. The mode is only entered at a safe point (when the
%   junction is idle or clearing), never mid-phase -- and because nothing goes
%   green in NIGHT, the safety invariant still holds, so
%   check_junction_safety('Junction4Way') should still PASS.
%
%   Run it with:  create_junction_4way;  run_demo('Junction4Way')
%   Toggle the "ns_demand" / "ew_demand" / "night_demand" switches while it runs.
%
%   Talking points (see worksheet): fairness/starvation, green extension while
%   cars keep arriving, adding dedicated turn phases, and how per-arm lamps
%   would scale to 12 outputs -- and why hierarchy keeps that manageable.
%
%   Idempotent: re-running rebuilds the model from scratch.

    H     = tl_helpers();
    model = 'Junction4Way';
    chart = H.newChartModel(model, 'Junction4Way');

    % --- inputs: a vehicle sensor per approach (order = input-port order) ----
    H.mkData(chart, 'ns_demand', 'Input', 'boolean');
    H.mkData(chart, 'ew_demand', 'Input', 'boolean');
    H.mkData(chart, 'night',     'Input', 'boolean');   % fault / night switch

    % --- outputs: NS lamps then EW lamps ------------------------------------
    H.mkData(chart, 'ns_red',   'Output');
    H.mkData(chart, 'ns_amber', 'Output');
    H.mkData(chart, 'ns_green', 'Output');
    H.mkData(chart, 'ew_red',   'Output');
    H.mkData(chart, 'ew_amber', 'Output');
    H.mkData(chart, 'ew_green', 'Output');

    lamps = @(nr,na,ng,er,ea,eg) sprintf( ...
        'en: ns_red=%d; ns_amber=%d; ns_green=%d; ew_red=%d; ew_amber=%d; ew_green=%d;', ...
        nr, na, ng, er, ea, eg);

    % counter used to flash the ambers in NIGHT mode
    H.mkData(chart, 'blink', 'Local', 'double', '0');

    % --- states -------------------------------------------------------------
    IDLE   = H.mkState(chart, ['IDLE\n'      lamps(1,0,0, 1,0,0)], [320 220 200 70]);
    NS_RA  = H.mkState(chart, ['NS_RA\n'     lamps(1,1,0, 1,0,0)], [ 60  60 200 70]);
    NS_GO  = H.mkState(chart, ['NS_GO\n'     lamps(0,0,1, 1,0,0)], [320  60 200 70]);
    NS_AMB = H.mkState(chart, ['NS_AMBER\n'  lamps(0,1,0, 1,0,0)], [580  60 200 70]);
    NS_CLR = H.mkState(chart, ['NS_CLEAR\n'  lamps(1,0,0, 1,0,0)], [580 220 200 70]);
    EW_RA  = H.mkState(chart, ['EW_RA\n'     lamps(1,0,0, 1,1,0)], [580 380 200 70]);
    EW_GO  = H.mkState(chart, ['EW_GO\n'     lamps(1,0,0, 0,0,1)], [320 380 200 70]);
    EW_AMB = H.mkState(chart, ['EW_AMBER\n'  lamps(1,0,0, 0,1,0)], [ 60 380 200 70]);
    EW_CLR = H.mkState(chart, ['EW_CLEAR\n'  lamps(1,0,0, 1,0,0)], [ 60 220 200 70]);
    % NIGHT / FAULT mode: every approach flashes amber together (no greens, so
    % the safety invariant still holds). Same flashing trick as the Pelican --
    % toggle the ambers on a counter in the "during" action.
    NIGHT  = H.mkState(chart, ['NIGHT\n' ...
        'en: ns_red=0; ns_green=0; ew_red=0; ew_green=0; ns_amber=1; ew_amber=1; blink=0;\n' ...
        'du: blink=blink+1; if blink>=5; ns_amber=1-ns_amber; ew_amber=1-ew_amber; blink=0; end'], ...
        [320 540 220 110]);

    H.mkDefault(chart, IDLE);

    % --- demand-driven dispatch (guards are mutually exclusive) -------------
    % NIGHT takes priority, but is only *entered* at a safe point (IDLE or a
    % clearance state), never mid-phase -- the same "finish safely first" idea
    % as the pedestrian crossing.
    H.mkTrans(chart, IDLE, NIGHT, '[night]');
    H.mkTrans(chart, IDLE, NS_RA, '[~night && ns_demand]');
    H.mkTrans(chart, IDLE, EW_RA, '[~night && ew_demand && ~ns_demand]');
    H.mkTrans(chart, NIGHT, IDLE, '[~night]');

    % NS phase
    H.mkTrans(chart, NS_RA,  NS_GO,  'after(2,sec)');
    H.mkTrans(chart, NS_GO,  NS_AMB, 'after(6,sec)');
    H.mkTrans(chart, NS_AMB, NS_CLR, 'after(3,sec)');
    % After NS clears: drop into NIGHT if requested, else serve EW if it is
    % waiting, otherwise idle.
    H.mkTrans(chart, NS_CLR, NIGHT, '[night && after(2,sec)]');
    H.mkTrans(chart, NS_CLR, EW_RA, '[~night && ew_demand && after(2,sec)]');
    H.mkTrans(chart, NS_CLR, IDLE,  '[~night && ~ew_demand && after(2,sec)]');

    % EW phase
    H.mkTrans(chart, EW_RA,  EW_GO,  'after(2,sec)');
    H.mkTrans(chart, EW_GO,  EW_AMB, 'after(6,sec)');
    H.mkTrans(chart, EW_AMB, EW_CLR, 'after(3,sec)');
    % After EW clears: drop into NIGHT if requested, else serve NS if it is
    % waiting, otherwise idle.
    H.mkTrans(chart, EW_CLR, NIGHT, '[night && after(2,sec)]');
    H.mkTrans(chart, EW_CLR, NS_RA, '[~night && ns_demand && after(2,sec)]');
    H.mkTrans(chart, EW_CLR, IDLE,  '[~night && ~ns_demand && after(2,sec)]');

    % --- harness: sensor + night switches, and lamp logging -----------------
    addSensorSwitch(model, 'ns',    'Junction4Way', 1, 40);
    addSensorSwitch(model, 'ew',    'Junction4Way', 2, 200);
    addSensorSwitch(model, 'night', 'Junction4Way', 3, 360);
    H.addOutputLogging(model, 'Junction4Way', ...
        {'ns_red','ns_amber','ns_green','ew_red','ew_amber','ew_green'});
    H.configDiscrete(model, 80);

    % --- visual: one head per approach (NS and EW) --------------------------
    C = H.colors;
    heads = { {[860 40], [1 2 3], [C.red; C.amber; C.green]}, ...   % NS approach
              {[980 40], [4 5 6], [C.red; C.amber; C.green]} };      % EW approach
    H.finish(model, chart, heads);
end

function addSensorSwitch(model, tag, chartName, inputPort, y)
%ADDSENSORSWITCH  A named, double-clickable demand switch for one approach.
    off = [model '/' tag '_off'];  on = [model '/' tag '_on'];
    sw  = [model '/' tag '_demand'];
    add_block('simulink/Sources/Constant', off, 'Value', '0', ...
              'OutDataTypeStr', 'boolean', 'Position', [20 y      60 y+30]);
    add_block('simulink/Sources/Constant', on,  'Value', '1', ...
              'OutDataTypeStr', 'boolean', 'Position', [20 y+60   60 y+90]);
    add_block('simulink/Signal Routing/Manual Switch', sw, 'Position', [120 y+10 160 y+70]);
    add_line(model, [tag '_off/1'], [tag '_demand/1'], 'autorouting', 'on');
    add_line(model, [tag '_on/1'],  [tag '_demand/2'], 'autorouting', 'on');
    add_line(model, [tag '_demand/1'], sprintf('%s/%d', chartName, inputPort), 'autorouting', 'on');
end
