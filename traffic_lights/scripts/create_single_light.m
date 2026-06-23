function create_single_light()
%CREATE_SINGLE_LIGHT  Day 1: a single UK traffic light that cycles on a timer.
%
%   Builds model TrafficLight.slx containing a Stateflow chart "SingleLight"
%   that walks the UK signal sequence:
%
%       RED  ->  RED+AMBER  ->  GREEN  ->  AMBER  ->  RED  (repeat)
%
%   Each state turns the three lamp outputs (red, amber, green) on or off in
%   its entry action, and a timed transition (after(n,sec)) moves to the next
%   state. There are no inputs yet -- the light just runs.
%
%   Run it with:  create_single_light;  run_demo('TrafficLight')
%
%   Idempotent: re-running rebuilds the model from scratch.

    H     = tl_helpers();
    model = 'TrafficLight';
    chart = H.newChartModel(model, 'SingleLight');

    % --- outputs: one lamp each (0 = off, 1 = on). Order fixes port numbers --
    H.mkData(chart, 'red',   'Output');
    H.mkData(chart, 'amber', 'Output');
    H.mkData(chart, 'green', 'Output');

    % --- states (entry action sets the lamp pattern) ------------------------
    RED      = H.mkState(chart, 'RED\nen: red=1; amber=0; green=0;',       [ 60  60 200 70]);
    REDAMBER = H.mkState(chart, 'RED_AMBER\nen: red=1; amber=1; green=0;', [340  60 200 70]);
    GREEN    = H.mkState(chart, 'GREEN\nen: red=0; amber=0; green=1;',     [340 240 200 70]);
    AMBER    = H.mkState(chart, 'AMBER\nen: red=0; amber=1; green=0;',     [ 60 240 200 70]);

    % --- a light always starts on RED ---------------------------------------
    H.mkDefault(chart, RED);

    % --- timed sequence (dwell times in seconds) ----------------------------
    H.mkTrans(chart, RED,      REDAMBER, 'after(5,sec)');
    H.mkTrans(chart, REDAMBER, GREEN,    'after(2,sec)');
    H.mkTrans(chart, GREEN,    AMBER,    'after(5,sec)');
    H.mkTrans(chart, AMBER,    RED,      'after(3,sec)');

    % --- harness: log the three lamps, fixed-step discrete solver -----------
    H.addOutputLogging(model, 'SingleLight', {'red', 'amber', 'green'});
    H.configDiscrete(model, 45);    % stop after 45 s (~3 full cycles)

    H.finish(model, chart);
end
