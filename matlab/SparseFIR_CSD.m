function SparseFIR_CSD_demo()
% SparseFIR_CSD_demo
% ----------------------------------------------------------
% Prototype of Li et al. (2025) low‑complexity design, adapted
% to a 1‑D low‑pass FIR filter.  Stages:
%   1. dense Parks‑McClellan design
%   2. sparsify by keeping K largest taps
%   3. CSD quantise + greedy digit‑sensitivity pruning
%   4. cost & error metrics + plots
%
% 2025‑04‑16  (chatGPT sample)

% ---------- user parameters ---------------------------------------------
N        = 64;       % Filter order (N+1 taps, even)
K        = 24;       % Target non‑zero taps after sparsification
B        = 16;       % CSD word‑length (bits)
omega_p  = 0.4;      % Pass‑band edge  (×pi rad, 0…1)
omega_s  = 0.6;      % Stop‑band start
delta_p  = 0.01;     % Pass‑band ripple (abs)
alpha_s  = 40;       % Stop‑band attenuation (dB)
delta_s  = 10^(-alpha_s/20);        % Stop‑band ripple
plotFlag = true;     % Show magnitude responses
% -------------------------------------------------------------------------

% ---------- 1. dense reference filter -----------------------------------
F = [0      omega_p   omega_s   1];          % 4 breakpoints
A = [1      1         0         0];          % desired amplitudes (same length!)
W = [1      10];                             % band weights  (pass, stop)
h_dense = firpm(N, F, A, W);                 % length N+1

% ---------- 2. magnitude‑based sparsification ---------------------------
[~, idx] = sort(abs(h_dense), 'descend');
mask            = false(size(h_dense));
mask(idx(1:K))  = true;
h_sparse        = h_dense .* mask;           % zero weak taps

% ---------- 3. CSD quantise and digit‑prune -----------------------------
% 3a. CSD coding  ---------------------------------------------------------
[D, q]  = csd_quantise(h_sparse, B);         % D: K×B digit matrix
                                            % q: reconstructed coeffs
% 3b. Greedy sensitivity‑driven digit removal
D_opt   = digit_elimination(D, h_sparse, q, F, A, W, ...
                            delta_p, delta_s);

h_opt   = csd2dec(D_opt);                   % final coefficients

% ---------- 4. Metrics ---------------------------------------------------
[m_dense, e_dense] = metrics(h_dense, F, A, W);
[m_sparse, e_sparse] = metrics(h_sparse, F, A, W);
[m_opt,   e_opt]   = metrics(h_opt,   F, A, W);

fprintf('\n%-12s %6s %6s %6s %10s\n', ...
    'Version', 'NC', 'NB', 'NA', 'MSE');
report('Reference', m_dense, e_dense);
report('Sparse+Q ', m_sparse, e_sparse);
report('Proposed  ', m_opt,   e_opt);

% ---------- 5. Plot ------------------------------------------------------
if plotFlag
    figure; hold on;
    [H,f] = freqz(h_dense, 1, 1024);
    plot(f/pi, abs(H), 'LineWidth',1.2);
    [H,f] = freqz(h_sparse,1,1024);
    plot(f/pi, abs(H), '--');
    [H,f] = freqz(h_opt,1,1024);
    plot(f/pi, abs(H), '-.');
    legend('Dense','Sparse (K taps)','Proposed');
    xlabel('\omega / \pi'); ylabel('|H(e^{j\omega})|');
    grid on; title('Magnitude responses');
end
end % ------------------ end main -----------------------------------------

% ========================================================================
%                       Helper functions
% ========================================================================

function [D, q] = csd_quantise(h, B)
% Convert real‑valued vector h to B‑bit CSD digit matrix D (±1/0).
% D is length(h) × B  (LSB = col‑1).
L = numel(h);
D = zeros(L, B);
for n = 1:L
    x = abs(h(n));
    for b = B:-1:1
        pow = 2^(b-1);
        if x >= pow
            D(n,b) =  1;
            x = x - pow;
        end
    end
    % Canonical signed‑digit recoding (no adjacent non‑zeros)
    for b = 1:B-1
        if D(n,b)==1 && D(n,b+1)==1
            D(n,b)   = -1;
            D(n,b+1) =  0;
            k = b+1;
            while k<=B && D(n,k)==-1
                D(n,k)=0; k=k+1;
            end
            if k<=B, D(n,k)=D(n,k)+1; end
        end
    end
    if h(n)<0, D(n,:) = -D(n,:); end
end
q = csd2dec(D);
end

function x = csd2dec(D)
% Convert digit matrix back to decimal.
B = size(D,2);
pow2 = 2.^(0:B-1);
x = D * pow2.';
end

function D = digit_elimination(D, h_sparse, q0, F, A, W, dp, ds)
% Remove least‑sensitive non‑zero digits while specs hold.
% Sensitivity = squared error increase when digit→0.
B = size(D,2); L = numel(h_sparse);
digits_idx = find(D);                % linear indices of non‑zeros
while true
    best_inc = Inf; best_pos = [];
    for ii = 1:numel(digits_idx)
        pos = digits_idx(ii);
        D_try      = D; D_try(pos)=0;
        h_try      = csd2dec(D_try);
        [~, err]   = metrics(h_try, F, A, W);
        if err.mse > dp || err.stop_max > ds
            continue;   % violates ripple spec
        end
        inc = err.mse;
        if inc < best_inc
            best_inc = inc; best_pos = pos;
        end
    end
    if isempty(best_pos), break; end   % no removable digit
    D(best_pos)=0;                     % commit removal
    digits_idx = digits_idx(digits_idx~=best_pos);
end
end

function [met, err] = metrics(h, F, A, W)
% Return hardware cost proxies and numeric error measures.
NC = nnz(abs(h)>eps);
% count signed digits
[~, q] = csd_quantise(h, 16);         % fixed 16‑bit for counting
NB = nnz(q);
NA = NB - NC;                         % rough: adder per extra digit
% error metrics
[H, w]  = freqz(h, 1, 2048);
mag     = abs(H);
passIdx = w/pi <= F(2);
stopIdx = w/pi >= F(3);
err.pass_max = max(abs(mag(passIdx)-1));
err.stop_max = max(mag(stopIdx));
err.mse      = mean((mag - interp1(F, A, w/pi, 'linear')).^2);
met = struct('NC',NC,'NB',NB,'NA',NA);
end

function report(tag, m, e)
fprintf('%-12s %6d %6d %6d %1.4e\n', tag, ...
    m.NC, m.NB, m.NA, e.mse);
end
