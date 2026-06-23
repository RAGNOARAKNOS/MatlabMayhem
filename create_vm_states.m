function create_vm_states()
%CREATE_VM_STATES Populate the VirtualMachine Stateflow chart in Datacentre.slx.
%
%   Builds the state machine for a VMware vSphere virtual machine. The three
%   stable states match the canonical VirtualMachinePowerState enum used by
%   the vSphere API (poweredOff, poweredOn, suspended). The transitional
%   states (PoweringOn, PoweringOff, Suspending, Resuming, Resetting) model
%   the operations that move a VM between those power states.
%
%   The user/hypervisor commands are modelled as local Stateflow events so
%   the chart stays self-contained (no external trigger ports are added).
%
%   This script is idempotent: re-running it clears and rebuilds the chart.Stateflow programmatic API

    modelFile = fullfile(fileparts(mfilename('fullpath')), 'Datacentre.slx');
    model     = 'Datacentre';

    load_system(modelFile);
    try
        chart = find(sfroot, '-isa', 'Stateflow.Chart', 'Name', 'VirtualMachine');
        assert(isscalar(chart), 'Expected exactly one VirtualMachine chart, found %d.', numel(chart));

        % --- make idempotent: wipe any previous contents --------------------
        delete(chart.find('-isa', 'Stateflow.Transition'));
        delete(chart.find('-isa', 'Stateflow.State'));
        delete(chart.find('-isa', 'Stateflow.Event'));

        % --- VMware operations, modelled as local events --------------------
        cmds = {'PowerOn', 'PowerOff', 'Suspend', 'Resume', 'Reset'};
        for i = 1:numel(cmds)
            e = Stateflow.Event(chart);
            e.Name  = cmds{i};
            e.Scope = 'Local';
        end

        % --- states ---------------------------------------------------------
        % canonical power states (stable) + operational states (transitional)
        poweredOff  = mkState(chart, 'PoweredOff',  [ 60  60 150 60]);
        poweringOn  = mkState(chart, 'PoweringOn',  [340  60 150 60]);
        poweredOn   = mkState(chart, 'PoweredOn',   [340 220 150 60]);
        poweringOff = mkState(chart, 'PoweringOff', [ 60 220 150 60]);
        suspending  = mkState(chart, 'Suspending',  [620 220 150 60]);
        suspended   = mkState(chart, 'Suspended',   [620 380 150 60]);
        resuming    = mkState(chart, 'Resuming',    [340 380 150 60]);
        resetting   = mkState(chart, 'Resetting',   [620  60 150 60]);

        % --- default transition: a VM starts powered off --------------------
        dt = Stateflow.Transition(chart);
        dt.Destination       = poweredOff;
        dt.DestinationOClock = 0;
        cx = poweredOff.Position(1) + poweredOff.Position(3) / 2;
        ty = poweredOff.Position(2);
        dt.SourceEndpoint = [cx, ty - 40];
        dt.MidPoint       = [cx, ty - 20];

        % --- command-driven transitions (user / hypervisor actions) ---------
        mkTrans(chart, poweredOff, poweringOn,  'PowerOn');
        mkTrans(chart, poweredOn,  poweringOff, 'PowerOff');
        mkTrans(chart, poweredOn,  suspending,  'Suspend');
        mkTrans(chart, suspended,  resuming,    'Resume');
        mkTrans(chart, poweredOn,  resetting,   'Reset');

        % --- automatic completion transitions out of transitional states ----
        mkTrans(chart, poweringOn,  poweredOn,  '');
        mkTrans(chart, poweringOff, poweredOff, '');
        mkTrans(chart, suspending,  suspended,  '');
        mkTrans(chart, resuming,    poweredOn,  '');
        mkTrans(chart, resetting,   poweredOn,  '');

        save_system(model);
        nStates = numel(chart.find('-isa', 'Stateflow.State'));
        fprintf('VirtualMachine chart populated with %d states.\n', nStates);
    catch ME
        close_system(model, 0);
        rethrow(ME);
    end
    close_system(model, 0);
end

function s = mkState(chart, name, pos)
    s = Stateflow.State(chart);
    s.LabelString = name;
    s.Position    = pos;   % [x y width height]
end

function t = mkTrans(chart, src, dst, label)
    t = Stateflow.Transition(chart);
    t.Source      = src;
    t.Destination = dst;
    if ~isempty(label)
        t.LabelString = label;
    end
end
