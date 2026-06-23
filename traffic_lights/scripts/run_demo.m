function out = run_demo(model, stopTime)
%RUN_DEMO  Simulate a traffic-light model and plot every logged lamp signal.
%
%   run_demo(MODEL) loads MODEL (e.g. 'TrafficLight'), opens its Stateflow
%   chart so you can watch the states light up during the run, simulates it,
%   and draws a timing chart of every logged output as a stack of stairs
%   plots. This is the "watch it work" step at the end of each day.
%
%   run_demo(MODEL, STOPTIME) overrides the stop time (seconds).
%
%   out = run_demo(...) also returns the Simulink.SimulationOutput.
%
%   Tip: for models with a Manual Switch input (Day 2 / Day 3), double-click
%   the switch while the simulation is running to toggle the input live.

    if nargin < 1 || isempty(model), model = 'TrafficLight'; end

    if ~bdIsLoaded(model), load_system(model); end
    if nargin >= 2 && ~isempty(stopTime)
        set_param(model, 'StopTime', num2str(stopTime));
    end

    % Open the chart so Stateflow animation highlights the active state.
    % (A Stateflow chart is opened via its own view/Path, not open_system(obj).)
    charts = find(sfroot, '-isa', 'Stateflow.Chart');
    charts = charts(arrayfun(@(c) startsWith(c.Path, [model '/']), charts));
    if ~isempty(charts)
        try
            charts(1).view;             % open the Stateflow editor for animation
        catch
            open_system(charts(1).Path); % fallback: open the chart block by path
        end
    else
        open_system(model);             % no chart found: just show the model
    end

    out = sim(model);

    % ---- plot every logged signal as a timing diagram ----------------------
    ds = out.yout;
    n  = ds.numElements;
    figure('Name', [model ' - timing diagram'], 'Color', 'w');
    for k = 1:n
        el = ds.getElement(k);
        ax = subplot(n, 1, k);
        stairs(el.Values.Time, squeeze(el.Values.Data), 'LineWidth', 1.5);
        ylim(ax, [-0.2 1.2]); yticks(ax, [0 1]); yticklabels(ax, {'off', 'on'});
        ylabel(ax, el.Name, 'Interpreter', 'none', 'Rotation', 0, ...
               'HorizontalAlignment', 'right');
        grid(ax, 'on');
        if k < n, set(ax, 'XTickLabel', []); end
    end
    xlabel('time (s)');
    sgtitle(sprintf('%s lamp timing', model), 'Interpreter', 'none');
end
