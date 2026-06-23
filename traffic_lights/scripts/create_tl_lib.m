function create_tl_lib()
%CREATE_TL_LIB  Build a Simulink LIBRARY holding one reusable traffic light.
%
%   This is the heart of the "modularity & reuse" lesson. Instead of hand-coding
%   a light's behaviour over and over, we define it ONCE here as a reusable
%   Stateflow component, "TrafficLightUnit", inside a library (tl_lib.slx).
%   create_junction_modular.m then *links* this one component four times to make
%   a whole crossroads. Edit the unit here and every junction that links it
%   updates -- that is the payoff of true reuse.
%
%   TrafficLightUnit -- a single UK light driven by a command:
%       input  : go      (true = "you should be green")
%       outputs: r,a,g   (the three lamps, 0/1)
%                is_red  (true only when fully stopped on red -- the controller
%                         uses this as the safety interlock)
%
%       RED --[go]--> RED_AMBER --after(2s)--> GREEN --[~go]--> AMBER
%           --after(2s)--> RED
%
%   The unit knows *how a light works*; it knows nothing about junctions. That
%   separation is what makes it reusable.
%
%   Run it with:  create_tl_lib   (then create_junction_modular)
%   Idempotent: re-running rebuilds the library from scratch.

    H   = tl_helpers();
    lib = 'tl_lib';

    if bdIsLoaded(lib), close_system(lib, 0); end
    ws = warning('off', 'all');         % silence "shadowing" on rebuild
    new_system(lib, 'Library');
    warning(ws);

    add_block('sflib/Chart', [lib '/TrafficLightUnit']);
    chart = H.chartByPath([lib '/TrafficLightUnit']);
    chart.ActionLanguage = 'MATLAB';
    chart.ChartUpdate    = 'DISCRETE';
    try, chart.SampleTime = '0.1'; catch, end

    % --- interface (the "contract" other components rely on) ----------------
    H.mkData(chart, 'go',     'Input',  'boolean');
    H.mkData(chart, 'r',      'Output');            % port 1
    H.mkData(chart, 'a',      'Output');            % port 2
    H.mkData(chart, 'g',      'Output');            % port 3
    H.mkData(chart, 'is_red', 'Output', 'boolean'); % port 4

    % --- behaviour (the UK light sequence, reacting to the command) ---------
    RED = H.mkState(chart, 'RED\nen: r=1; a=0; g=0; is_red=true;',        [ 60  60 200 70]);
    RA  = H.mkState(chart, 'RED_AMBER\nen: r=1; a=1; g=0; is_red=false;', [340  60 200 70]);
    GRN = H.mkState(chart, 'GREEN\nen: r=0; a=0; g=1; is_red=false;',     [340 220 200 70]);
    AMB = H.mkState(chart, 'AMBER\nen: r=0; a=1; g=0; is_red=false;',     [ 60 220 200 70]);

    H.mkDefault(chart, RED);
    H.mkTrans(chart, RED, RA,  '[go]');           % told to go: start the sequence
    H.mkTrans(chart, RA,  GRN, 'after(2,sec)');
    H.mkTrans(chart, GRN, AMB, '[~go]');          % told to stop: begin stopping
    H.mkTrans(chart, AMB, RED, 'after(2,sec)');

    Simulink.BlockDiagram.arrangeSystem(lib);
    save_system(lib);
    fprintf('Built library %s with reusable TrafficLightUnit (4 states).\n', lib);
end
