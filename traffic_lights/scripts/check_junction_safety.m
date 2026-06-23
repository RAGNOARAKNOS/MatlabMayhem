function ok = check_junction_safety(model)
%CHECK_JUNCTION_SAFETY  Verify the junction never shows two greens at once.
%
%   ok = check_junction_safety(MODEL) simulates MODEL (default 'Junction'),
%   reads the logged lamp signals, and checks the safety invariant:
%
%       at no point in time are ns_green AND ew_green both on.
%
%   This is the difference between "it looks right when I watch it" and
%   "I have evidence it is right". It prints PASS/FAIL and, on failure, the
%   first time the invariant was violated. Returns true if safe.
%
%   Try breaking the junction on purpose (e.g. delete the ALL_RED clearance
%   transitions, or make NS_GO transition straight into EW_GO) and re-run
%   this -- watch it catch the bug.

    if nargin < 1 || isempty(model), model = 'Junction'; end
    if ~bdIsLoaded(model), load_system(model); end

    out = sim(model);
    ns_green = signalByName(out.yout, 'ns_green');
    ew_green = signalByName(out.yout, 'ew_green');

    t      = ns_green.Time;
    both   = (ns_green.Data > 0.5) & (ew_green.Data > 0.5);
    ok     = ~any(both);

    if ok
        fprintf('PASS: ns_green and ew_green are never on together (%d samples checked).\n', ...
                numel(t));
    else
        firstBad = t(find(both, 1, 'first'));
        fprintf(2, 'FAIL: both approaches green at t = %.2f s. Safety invariant violated!\n', ...
                firstBad);
    end
end

function el = signalByName(ds, name)
%SIGNALBYNAME  Pull one named signal (timeseries) out of a logged Dataset.
    avail = cell(1, ds.numElements);
    for k = 1:ds.numElements
        e = ds.getElement(k);
        avail{k} = e.Name;
        if strcmp(e.Name, name), el = e.Values; return; end
    end
    error('Signal "%s" not found in the logged output. Available: %s', ...
          name, strjoin(avail, ', '));
end
