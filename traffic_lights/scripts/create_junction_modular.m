function create_junction_modular()
%CREATE_JUNCTION_MODULAR  The 4-way junction, built from REUSABLE components.
%
%   Same job as create_junction_4way.m, but assembled instead of hand-coded.
%   This is the modularity & reuse lesson:
%
%     * create_junction_4way.m  -- ONE big chart; the six-lamp pattern is
%       written out again in every state (lots of duplication).
%     * create_junction_modular -- links the reusable TrafficLightUnit (from
%       tl_lib, see create_tl_lib.m) FOUR times (N/S/E/W) and adds a small
%       Controller that only decides *whose turn it is*. The light behaviour is
%       defined once and reused; edit the unit and all four arms change.
%
%   Architecture (separation of concerns):
%       Controller  -- knows the junction POLICY (phase order, all-red gap,
%                      "wait until the units are red before swapping"). Talks to
%                      the units only through go / is_red.
%       N,S,E,W     -- four linked copies of TrafficLightUnit; each knows only
%                      how a UK light sequences.
%
%   Controller drives ns_go -> N,S and ew_go -> E,W, and watches N.is_red /
%   E.is_red as the safety interlock. ns_green/ew_green are exported so the
%   EXISTING check_junction_safety works on this model unchanged.
%
%   Run it with:  create_tl_lib;  create_junction_modular;
%                 run_demo('Junction4WayModular')
%                 check_junction_safety('Junction4WayModular')
%
%   Idempotent: re-running rebuilds the model from scratch.

    H     = tl_helpers();
    lib   = 'tl_lib';
    model = 'Junction4WayModular';

    % --- make sure the reusable component exists and is loaded --------------
    if ~bdIsLoaded(lib)
        if exist('tl_lib.slx', 'file'), load_system(lib); else, create_tl_lib; end
    end

    if bdIsLoaded(model), close_system(model, 0); end
    ws = warning('off', 'all');
    new_system(model);
    warning(ws);

    % --- the Controller chart (junction policy only) ------------------------
    add_block('sflib/Chart', [model '/Controller']);
    ctrl = H.chartByPath([model '/Controller']);
    ctrl.ActionLanguage = 'MATLAB';
    ctrl.ChartUpdate    = 'DISCRETE';
    try, ctrl.SampleTime = '0.1'; catch, end

    H.mkData(ctrl, 'ns_red', 'Input',  'boolean');   % in 1: are N/S fully red?
    H.mkData(ctrl, 'ew_red', 'Input',  'boolean');   % in 2: are E/W fully red?
    H.mkData(ctrl, 'ns_go',  'Output', 'boolean');   % out 1
    H.mkData(ctrl, 'ew_go',  'Output', 'boolean');   % out 2

    NSGO  = H.mkState(ctrl, 'NS_GO\nen: ns_go=true; ew_go=false;',  [ 60  60 200 60]);
    NSEND = H.mkState(ctrl, 'NS_END\nen: ns_go=false;',            [340  60 200 60]);
    AR1   = H.mkState(ctrl, 'ALL_RED1',                            [620  60 200 60]);
    EWGO  = H.mkState(ctrl, 'EW_GO\nen: ew_go=true; ns_go=false;',  [620 240 200 60]);
    EWEND = H.mkState(ctrl, 'EW_END\nen: ew_go=false;',            [340 240 200 60]);
    AR2   = H.mkState(ctrl, 'ALL_RED2',                            [ 60 240 200 60]);

    H.mkDefault(ctrl, NSGO);
    H.mkTrans(ctrl, NSGO,  NSEND, 'after(6,sec)');   % NS green time
    H.mkTrans(ctrl, NSEND, AR1,   '[ns_red]');       % wait until units are red
    H.mkTrans(ctrl, AR1,   EWGO,  'after(2,sec)');   % all-red clearance
    H.mkTrans(ctrl, EWGO,  EWEND, 'after(6,sec)');   % EW green time
    H.mkTrans(ctrl, EWEND, AR2,   '[ew_red]');
    H.mkTrans(ctrl, AR2,   NSGO,  'after(2,sec)');

    % --- four LINKED instances of the reusable unit -------------------------
    arms = {'N', 'S', 'E', 'W'};
    pos  = [ 80 380; 300 380; 520 380; 740 380];
    for k = 1:numel(arms)
        add_block([lib '/TrafficLightUnit'], [model '/' arms{k}], ...
                  'Position', [pos(k,1) pos(k,2) pos(k,1)+120 pos(k,2)+80]);
    end

    % --- wiring: controller <-> units (go out, is_red feedback) -------------
    add_line(model, 'Controller/1', 'N/1', 'autorouting', 'on');  % ns_go -> N.go
    add_line(model, 'Controller/1', 'S/1', 'autorouting', 'on');  % ns_go -> S.go
    add_line(model, 'Controller/2', 'E/1', 'autorouting', 'on');  % ew_go -> E.go
    add_line(model, 'Controller/2', 'W/1', 'autorouting', 'on');  % ew_go -> W.go
    % The is_red feedback closes a loop (go -> unit -> is_red -> controller).
    % A one-step Unit Delay breaks that algebraic loop -- standard practice for
    % feedback between two state machines, and negligible at a 0.1 s step.
    add_block('simulink/Discrete/Unit Delay', [model '/d_ns'], ...
              'InitialCondition', '0', 'Position', [600 470 640 500]);
    add_block('simulink/Discrete/Unit Delay', [model '/d_ew'], ...
              'InitialCondition', '0', 'Position', [600 540 640 570]);
    add_line(model, 'N/4',   'd_ns/1',        'autorouting', 'on');  % N.is_red ->
    add_line(model, 'd_ns/1', 'Controller/1', 'autorouting', 'on');  %   -> ns_red
    add_line(model, 'E/4',   'd_ew/1',        'autorouting', 'on');  % E.is_red ->
    add_line(model, 'd_ew/1', 'Controller/2', 'autorouting', 'on');  %   -> ew_red

    % --- export ns_green / ew_green so the existing checker can be reused ----
    add_block('simulink/Sinks/Out1', [model '/ns_green'], 'Port', '1');
    add_block('simulink/Sinks/Out1', [model '/ew_green'], 'Port', '2');
    hns = add_line(model, 'N/3', 'ns_green/1', 'autorouting', 'on'); set_param(hns, 'Name', 'ns_green');
    hew = add_line(model, 'E/3', 'ew_green/1', 'autorouting', 'on'); set_param(hew, 'Name', 'ew_green');

    H.configDiscrete(model, 60);

    % --- tidy, then add one lamp head per arm (12 lamps = a full crossroads) -
    Simulink.BlockDiagram.arrangeSystem(model);
    C = H.colors;
    rag = [C.red; C.amber; C.green];
    heads = [1000 40; 1130 40; 1260 40; 1390 40];
    for k = 1:numel(arms)
        H.addLampHead(model, [model '/' arms{k}], heads(k,:), [1 2 3], rag);
    end

    save_system(model);
    nCtrl = numel(ctrl.find('-isa', 'Stateflow.State'));
    fprintf('Built %s: Controller (%d states) + 4 linked TrafficLightUnit instances.\n', ...
            model, nCtrl);
end
