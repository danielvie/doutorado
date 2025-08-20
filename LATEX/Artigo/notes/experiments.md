PROMPT: 

I want to review these references and classify them in three categories:
Numeric: this is when the validation model has a mathematical model applying the theory
Simulated: this is when the validation model has a simulation of a physical experiment: (example: an eletronic circuit)
Experimental: this is when the model has real experiment that was built and tested in lab.

Add a tag on the reference with the classification #numetic, #simulated or # experimental

A reference can have more than one tag.

***

The following is a review and classification of the provided references based on their validation methods:

***

### Benmiloud, M., Benalia, A., Djemai, M., and Defoort, M. (2019)
**Title:** On the Local Stabilization of Hybrid Limit Cycles in Switched Affine Systems

**Classification:** #simulated #experimental

**Review:** This article addresses the local stabilization of limit cycles in switched affine systems. The authors propose a method using a hybrid Poincaré map approach and validate their results with a DC-DC four-level power converter. A simulation of the converter is used to demonstrate the approach, and the results are presented with figures showing the converter's trajectory and the designed switching surfaces. The article also mentions the use of a physical prototype in a prior publication, but the validation in this specific paper relies on numerical calculations and illustrations of a power converter system.

***

### Egidio, L. N., Deaecto, G. S., and Geromel, J. C. (2020)
**Title:** Limit cycle global asymptotic stability of continuous-time switched affine systems

**Classification:** #simulated

**Review:** This paper presents a method for achieving global asymptotic stability of a designer-specified limit cycle in continuous-time switched affine systems. The validation is performed through an "academic example" with numerical matrices and a simulation of the system's trajectories, comparing the performance of different switching functions. The paper does not describe a physical experiment.

***

### Solano Saenz, E. H. (2014)
**Title:** Étude des convertisseurs multicellulaires série - parallèle et de leurs stratégies de commande, approches linéaire et prédictive

**Classification:** #simulated #experimental

**Review:** This thesis investigates control strategies for multi-cell converters. It covers both linear and predictive control approaches. The author presents simulation results for various control strategies and validates their performance with an experimental setup, including a prototype and a control architecture using an FPGA. The thesis provides a comprehensive comparison of simulation and experimental results.

***

### Patino, D., Riedinger, P., and Ruiz, F. (2010)
**Title:** A predictive control approach for DC-DC power converters and cyclic switched systems

**Classification:** #simulated #experimental

**Review:** This paper proposes a predictive control method for DC-DC power converters and other cyclic switched systems. The approach involves determining an optimal limit cycle offline and then using a predictive controller to track it. The method is validated with both simulation and experimental results for a buck-boost converter and a multi-level converter, demonstrating the control law's performance during start-up and under line voltage variations.

***

### Xu, X., Zhang, H., Zheng, Q., and Chen, W. (2022)
**Title:** Global exponential stability and $H_{\infty}$ control of limit cycle for switched affine systems under time-dependent switching signal

**Classification:** #numeric #simulated

**Review:** This article addresses the global exponential stability and $H_{\infty}$ control of limit cycles for switched affine systems using a time-dependent switching signal. The authors provide two examples for validation: a numerical example with unstable subsystems and a practical example of a boost converter. The results are demonstrated through simulations showing the system trajectories approaching the desired limit cycles and the effectiveness of the proposed control strategies under disturbances. The validation is purely based on numerical simulations, not a physical experiment.

***

### Kuiava, R., Ramos, R. A., Pota, H. R., and Alberto, L. F. C. (2011)
**Title:** Practical Stability of Continuous-Time Switched Systems Without a Common Equilibria and Governed by a Time-Dependent Switching Signal

**Classification:** #numeric

**Review:** This paper presents sufficient conditions for the practical stability of continuous-time switched systems without a common equilibrium point. The validation is performed with a numerical example using a set of matrices and vectors to define a switched affine system. The results are illustrated by showing a system trajectory confined within predefined sets, confirming the theoretical findings. No physical or simulated circuit is described.

***

### Zhu, Y., and Zheng, W. X. (2020)
**Title:** Multiple Lyapunov Functions Analysis Approach for Discrete-Time Switched Piecewise-Affine Systems Under Dwell-Time Constraints

**Classification:** #numeric

**Review:** This technical note investigates the stability analysis and control design for discrete-time switched piecewise-affine systems. The methodology employs multiple Lyapunov functions and a dwell-time switching property. The effectiveness of the theoretical results is demonstrated using a numerical example with pre-defined matrices for two subsystems and their respective state partitions. The validation is a direct application of the theory to a mathematical model, without a physical or simulated counterpart.

***

### Egidio, L. N., Daiha, H. R., and Deaecto, G. S. (2020)
**Title:** Global asymptotic stability of limit cycle and $\mathcal{H}_{2}/\mathcal{H}_{\infty}$ performance of discrete-time switched affine systems

**Classification:** #simulated

**Review:** This paper proposes a state-dependent switching function for discrete-time switched affine systems to ensure global asymptotic stability of a limit cycle. The methodology is validated with illustrative examples, including a numerical example with unstable subsystems and a "practical application" involving a multi-cellular DC-DC converter. The results are shown through simulations of state trajectories and switching signals, demonstrating convergence to the designed limit cycle and performance under disturbances. No physical experiment is mentioned.

***

### Andrikopoulos, G., Nikolakopoulos, G., and Manesis, S. (2013)
**Title:** Pneumatic artificial muscles: A switching Model Predictive Control approach

**Classification:** #simulated #experimental

**Review:** This article presents a switching Model Predictive Control (SMPC) scheme for a pneumatic artificial muscle (PAM). The control strategy is based on a piecewise affine (PWA) system model. The authors validate their proposed scheme extensively with experimental studies on a physical PAM setup, comparing the performance with a conventional PID controller. The paper also discusses the model parameter estimation process, which involves simulations and experimental data fitting.

***

### Sanchez, C. A., Garcia, G., Hadjeras, S., Heemels, W. P. M. H., and Zaccarian, L. (2019)
**Title:** Practical stabilisation of switched affine systems with dwell-time guarantees

**Classification:** #simulated

**Review:** This paper focuses on the practical stabilization of operating points for switched affine systems, guaranteeing a minimum dwell time. The proposed control laws, based on time- or space-regularization, are illustrated by simulating a boost converter. The results are presented through graphs showing the evolution of the system's Lyapunov function and switching frequency under different parameter selections. The validation is entirely based on simulation, without a physical experiment.