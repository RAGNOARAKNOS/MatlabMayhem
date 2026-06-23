function create_junction()
%CREATE_JUNCTION  Day 3: two interconnected lights at a crossroads.
%
%   Builds model Junction.slx with a Stateflow chart "Junction" that controls
%   two approaches -- North-South (NS) and East-West (EW) -- as a single
%   sequence of phases. The whole point is the SAFETY INVARIANT:
%
%       ns_green and ew_green must NEVER be on at the same time.
%
%   The controller guarantees it by construction: only one approach is ever
%   given green, and an ALL-RED clearance phase separates the swaps. Each
%   approach still shows the full UK sequence (red+amber before green, amber
%   before red).
%
%       NS_RA -> NS_GO -> NS_AMBER -> ALL_RED -> EW_RA -> EW_GO
%             -> EW_AMBER -> ALL_RED -> (repeat)
%
%   Run it with:   create_junction;  check_junction_safety('Junction')
%   or watch it:   create_junction;  run_demo('Junction')
%
%   Idempotent: re-running rebuilds the model from scratch.

    H     = tl_helpers();
    model = 'Junction';
    chart = H.newChartModel(model, 'Junction');

    % --- outputs: NS lamps then EW lamps (order = port order) ---------------
    H.mkData(chart, 'ns_red',   'Output');
    H.mkData(chart, 'ns_amber', 'Output');
    H.mkData(chart, 'ns_green', 'Output');
    H.mkData(chart, 'ew_red',   'Output');
    H.mkData(chart, 'ew_amber', 'Output');
    H.mkData(chart, 'ew_green', 'Output');

    % lamps(nr,na,ng, er,ea,eg) writes all six lamps in one entry action.
    lamps = @(nr,na,ng,er,ea,eg) sprintf( ...
        'en: ns_red=%d; ns_amber=%d; ns_green=%d; ew_red=%d; ew_amber=%d; ew_green=%d;', ...
        nr, na, ng, er, ea, eg);

    % --- phases (states). One approach moves while the other stays red ------
    NS_RA  = H.mkState(chart, ['NS_RA\n'    lamps(1,1,0, 1,0,0)], [ 60  60 200 70]);
    NS_GO  = H.mkState(chart, ['NS_GO\n'    lamps(0,0,1, 1,0,0)], [320  60 200 70]);
    NS_AMB = H.mkState(chart, ['NS_AMBER\n' lamps(0,1,0, 1,0,0)], [580  60 200 70]);
    ALLR1  = H.mkState(chart, ['ALL_RED\n'  lamps(1,0,0, 1,0,0)], [580 220 200 70]);
    EW_RA  = H.mkState(chart, ['EW_RA\n'    lamps(1,0,0, 1,1,0)], [580 380 200 70]);
    EW_GO  = H.mkState(chart, ['EW_GO\n'    lamps(1,0,0, 0,0,1)], [320 380 200 70]);
    EW_AMB = H.mkState(chart, ['EW_AMBER\n' lamps(1,0,0, 0,1,0)], [ 60 380 200 70]);
    ALLR2  = H.mkState(chart, ['ALL_RED2\n' lamps(1,0,0, 1,0,0)], [ 60 220 200 70]);

    % --- start from a clean red+amber on the NS approach --------------------
    H.mkDefault(chart, NS_RA);

    % --- the phase cycle (dwell times in seconds) ---------------------------
    H.mkTrans(chart, NS_RA,  NS_GO,  'after(2,sec)');
    H.mkTrans(chart, NS_GO,  NS_AMB, 'after(6,sec)');
    H.mkTrans(chart, NS_AMB, ALLR1,  'after(3,sec)');
    H.mkTrans(chart, ALLR1,  EW_RA,  'after(2,sec)');   % clearance before swap
    H.mkTrans(chart, EW_RA,  EW_GO,  'after(2,sec)');
    H.mkTrans(chart, EW_GO,  EW_AMB, 'after(6,sec)');
    H.mkTrans(chart, EW_AMB, ALLR2,  'after(3,sec)');
    H.mkTrans(chart, ALLR2,  NS_RA,  'after(2,sec)');   % clearance before swap

    % --- harness: log all six lamps -----------------------------------------
    H.addOutputLogging(model, 'Junction', ...
        {'ns_red','ns_amber','ns_green','ew_red','ew_amber','ew_green'});
    H.configDiscrete(model, 60);

    % --- visual: one head per approach (NS and EW) --------------------------
    C = H.colors;
    heads = { {[860 40], [1 2 3], [C.red; C.amber; C.green]}, ...   % NS approach
              {[980 40], [4 5 6], [C.red; C.amber; C.green]} };      % EW approach
    H.finish(model, chart, heads);
end
