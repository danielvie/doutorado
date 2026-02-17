
for the control, i have this flow in my simulation:

1. read analog signals
2. compute `ek = x - x_target`
3. compute `dtk = -K * ek`
4. compute conditioning `dtk = condition_dtk(dtk)`
5. update Ts from dtk
6. propagate simulation step

Ts: time vector of the signal
dtk: time correction for each segment
x_target: target vector
ek: error vector
K: gain matrix

---
organize the computation of the control so that these steps are easy to identity