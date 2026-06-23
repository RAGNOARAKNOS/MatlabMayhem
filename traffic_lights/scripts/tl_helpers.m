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
        'colors',        colourPalette(), ...
        'addLampHead',   @addLampHead, ...
        'finish',        @finish);
end

function c = colourPalette()
%COLOURPALETTE  Lamp colours used by the visual indicators (RGB, 0..1).
    c = struct('red',   [0.85 0.00 0.00], ...
               'amber', [1.00 0.65 0.00], ...
               'green', [0.00 0.70 0.15]);
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

function finish(model, chart, heads)
%FINISH  Auto-arrange, add visual lamp indicators, save and report.
%   HEADS (optional) describes one or more traffic-light "heads" to draw as
%   live Dashboard Lamp indicators. It is a cell array, each element a cell:
%       { [x y], portIndices, colourRows }
%   where PORTINDICES are chart output ports (top-to-bottom) and COLOURROWS is
%   an N-by-3 RGB matrix. Lamps light up during simulation -- much more
%   engaging than reading a timing chart. They are added *after* the
%   auto-arrange so their tidy stacked layout is preserved.
    Simulink.BlockDiagram.arrangeSystem(model);
    if nargin >= 3 && ~isempty(heads)
        addLampHeads(model, chart, heads);
    end
    save_system(model);
    n = numel(chart.find('-isa', 'Stateflow.State'));
    fprintf('Built %s: %d states.\n', model, n);
end

% ---------------------------------------------------------------------------
% Visual indicators (Dashboard Lamp blocks bound to chart outputs)
% ---------------------------------------------------------------------------
function addLampHeads(model, chart, heads)
%ADDLAMPHEADS  Draw each traffic-light head bound to one chart's outputs.
    chartBlk = [model '/' chart.Name];
    for h = 1:numel(heads)
        spec = heads{h};
        addLampHead(model, chartBlk, spec{1}, spec{2}, spec{3});
    end
end

function addLampHead(model, srcBlock, topLeft, ports, colours)
%ADDLAMPHEAD  A vertical stack of lamps bound to output ports of SRCBLOCK.
%   SRCBLOCK can be any block with output signals -- a Stateflow chart, or a
%   linked library unit (used by the modular junction). TOPLEFT = [x y];
%   PORTS = output-port indices (top-to-bottom); COLOURS = N-by-3 RGB.
    sz = 50; gap = 14;
    for i = 1:numel(ports)
        x = topLeft(1);
        y = topLeft(2) + (i - 1) * (sz + gap);
        addLamp(model, srcBlock, ports(i), colours(i, :), [x y x+sz y+sz]);
    end
end

function addLamp(model, chartBlk, portIndex, colour, pos)
%ADDLAMP  One Dashboard Lamp bound to output PORTINDEX of the chart.
%   Shows COLOUR when that lamp signal is 1, and a dark "off" colour otherwise.
    lib = 'simulink_hmi_blocks';
    if ~bdIsLoaded(lib), load_system(lib); end
    name = sprintf('%s/lamp_%s_%d', model, get_param(chartBlk, 'Name'), portIndex);
    add_block([lib '/Lamp'], name, 'Position', pos);
    ss = Simulink.HMI.SignalSpecification;
    ss.BlockPath       = Simulink.BlockPath(chartBlk);
    ss.OutputPortIndex = portIndex;
    set_param(name, 'Binding',      ss);
    set_param(name, 'StateColors',  struct('Value', 1, 'Color', colour));
    set_param(name, 'ColorDefault', [0.15 0.15 0.15]);   % dark = lamp off
end
