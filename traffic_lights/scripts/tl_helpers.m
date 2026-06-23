function H = tl_helpers()
%TL_HELPERS  Shared toolkit for the traffic-light teaching pack.
%
%   H = tl_helpers() returns a struct of function handles used by every
%   create_*.m builder in this folder. It keeps the builders terse and in the
%   same house style as create_vm_states.m (mkState / mkTrans), and adds a few
%   conveniences for data, default transitions, model configuration and the
%   simulation harness.
%
%   Usage inside a builder:
%       H = tl_helpers();
%       chart = H.newChartModel('TrafficLight', 'SingleLight');
%       red   = H.mkState(chart, 'RED\nen: ...', [60 60 150 60]);
%       ...
%       H.finish('TrafficLight', chart);
%
%   No toolboxes are touched at load time; the handles only do work when
%   called from MATLAB with Simulink + Stateflow installed.

    H = struct( ...
        'newChartModel', @newChartModel, ...
        'chartByPath',   @chartByPath, ...
        'mkState',       @mkState, ...
        'mkTrans',       @mkTrans, ...
        'mkDefault',     @mkDefault, ...
        'mkData',        @mkData, ...
        'configDiscrete',@configDiscrete, ...
        'addOutputLogging', @addOutputLogging, ...
        'addManualInput',   @addManualInput, ...
        'finish',        @finish);
end

% ---------------------------------------------------------------------------
% Model + chart creation
% ---------------------------------------------------------------------------
function chart = newChartModel(model, chartName)
%NEWCHARTMODEL  Create a fresh model containing one empty Stateflow chart.
%   Idempotent: an already-open model of the same name is closed first.
    if bdIsLoaded(model), close_system(model, 0); end
    % Suppress the harmless "model name is shadowing ..." warning that fires on
    % every rebuild once the .slx already exists on the path.
    ws = warning('off', 'all');
    new_system(model);
    warning(ws);
    add_block('sflib/Chart', [model '/' chartName]);
    chart = chartByPath([model '/' chartName]);
    chart.ActionLanguage = 'MATLAB';
    % Absolute-time temporal logic (after(n,sec)) needs a sample time.
    chart.ChartUpdate = 'DISCRETE';
    try
        chart.SampleTime = '0.1';      % property name varies slightly by release
    catch
        % older releases: sample time is inherited from the discrete solver
    end
end

function ch = chartByPath(p)
%CHARTBYPATH  Resolve a Stateflow.Chart object from its Simulink path.
    charts = find(sfroot, '-isa', 'Stateflow.Chart');
    ch = charts(arrayfun(@(c) strcmp(c.Path, p), charts));
    assert(isscalar(ch), 'Could not resolve chart at %s', p);
end

% ---------------------------------------------------------------------------
% Chart contents (states / transitions / data)
% ---------------------------------------------------------------------------
function s = mkState(chart, label, pos)
%MKSTATE  Add a state. LABEL may contain newlines for entry/during actions.
    s = Stateflow.State(chart);
    s.LabelString = sprintf(label);   % sprintf so '\n' in the label expands
    s.Position    = pos;              % [x y width height]
end

function t = mkTrans(chart, src, dst, label)
%MKTRANS  Add a transition src -> dst, optionally labelled (guard/event/timer).
    t = Stateflow.Transition(chart);
    t.Source      = src;
    t.Destination = dst;
    if nargin >= 4 && ~isempty(label)
        t.LabelString = label;
    end
end

function dt = mkDefault(chart, dst)
%MKDEFAULT  Add the default transition that selects the initial state DST.
    dt = Stateflow.Transition(chart);
    dt.Destination       = dst;
    dt.DestinationOClock = 0;
    cx = dst.Position(1) + dst.Position(3) / 2;
    ty = dst.Position(2);
    dt.SourceEndpoint = [cx, ty - 40];
    dt.MidPoint       = [cx, ty - 20];
end

function d = mkData(chart, name, scope, dtype, initVal)
%MKDATA  Add a data object. SCOPE: 'Input' | 'Output' | 'Local'.
%   Output/Input data automatically create chart block ports. INITVAL (a
%   string, e.g. 'false') sets the initial value -- needed for any Local data
%   that is read before it is first written.
    if nargin < 4 || isempty(dtype), dtype = 'double'; end
    d = Stateflow.Data(chart);
    d.Name     = name;
    d.Scope    = scope;
    d.DataType = dtype;
    if nargin >= 5 && ~isempty(initVal)
        d.Props.InitialValue = initVal;
    end
end

% ---------------------------------------------------------------------------
% Harness / model configuration
% ---------------------------------------------------------------------------
function configDiscrete(model, stopTime, step)
%CONFIGDISCRETE  Fixed-step discrete solver so temporal logic runs predictably.
    if nargin < 2 || isempty(stopTime), stopTime = 60;  end
    if nargin < 3 || isempty(step),     step     = 0.1; end
    set_param(model, ...
        'SolverType', 'Fixed-step', ...
        'Solver',     'FixedStepDiscrete', ...
        'FixedStep',  num2str(step), ...
        'StopTime',   num2str(stopTime), ...
        'SaveOutput', 'on', ...
        'SaveTime',   'on', ...
        'SaveFormat', 'Dataset', ...
        'OutputSaveName', 'yout', ...
        'TimeSaveName',   'tout');
end

function addOutputLogging(model, chartName, names)
%ADDOUTPUTLOGGING  Wire each chart Output to a root Outport so sim logs it.
%   NAMES must list the Output data in the order they were created on the
%   chart (that order fixes the chart block's output-port numbering).
    for k = 1:numel(names)
        outBlk = [model '/' names{k}];
        add_block('simulink/Sinks/Out1', outBlk, 'Port', num2str(k));
        h = add_line(model, sprintf('%s/%d', chartName, k), ...
                            sprintf('%s/1', names{k}), 'autorouting', 'on');
        % Name the signal so it is logged under that name in out.yout.
        set_param(h, 'Name', names{k});
    end
end

function addManualInput(model, chartName, inputPort)
%ADDMANUALINPUT  A double-clickable Manual Switch feeding a chart Input.
%   Off = 0, On = 1. During simulation the student double-clicks the switch
%   to "press the button"; it takes effect on the next time step.
%   INPUTPORT is the chart input-port number the switch should drive.
    if nargin < 3 || isempty(inputPort), inputPort = 1; end
    off = [model '/Off'];  on = [model '/On'];  sw = [model '/Press'];
    add_block('simulink/Sources/Constant', off, 'Value', '0', ...
              'OutDataTypeStr', 'boolean', 'Position', [40  40  80  70]);
    add_block('simulink/Sources/Constant', on,  'Value', '1', ...
              'OutDataTypeStr', 'boolean', 'Position', [40 120  80 150]);
    add_block('simulink/Signal Routing/Manual Switch', sw, 'Position', [170 70 200 120]);
    add_line(model, 'Off/1', 'Press/1', 'autorouting', 'on');
    add_line(model, 'On/1',  'Press/2', 'autorouting', 'on');
    add_line(model, 'Press/1', sprintf('%s/%d', chartName, inputPort), 'autorouting', 'on');
end

function finish(model, chart)
%FINISH  Auto-arrange, save and report, matching the repo's reporting style.
    Simulink.BlockDiagram.arrangeSystem(model);
    save_system(model);
    n = numel(chart.find('-isa', 'Stateflow.State'));
    fprintf('Built %s: %d states.\n', model, n);
end
