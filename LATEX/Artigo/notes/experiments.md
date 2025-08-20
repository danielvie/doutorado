### **Validation Methods in Switched Systems Research**

This document summarizes the validation methods used across several research papers on switched and hybrid systems. The methods are categorized into three types: **Numeric**, **Simulated**, and **Experimental**, reflecting different levels of testing from purely mathematical models to real-world physical setups.

***

### **Numeric Validation**

This category includes studies that use theoretical models and mathematical examples to validate their proposed control strategies. These methods focus on confirming the feasibility and accuracy of the underlying theory.

* **[Zhu 2019]**: This paper uses a numerical example to test a discrete-time switched piecewise-affine (PWA) system. It calculates the minimum modal dwell time (MDT) for stability and plots the system's open-loop and closed-loop responses to verify that the controller works as designed.
* **[kuiava_2011]**: The authors validate their work with an illustrative example of a continuous-time switched affine system with three unstable subsystems. They demonstrate that the system's trajectory, starting from within a defined initial set, remains confined to a larger specified safe region.
* **[Egidio 2020]**: This work uses a numerical example to show that state trajectories converge to a desired limit cycle. It compares the performance of min-type sampled, periodic, and non-sampled switching functions, concluding that the sampled function yields a smaller control cost.

***

### **Simulated Validation**

This approach involves creating a virtual model of a physical system to test and validate control algorithms. It allows researchers to evaluate performance under various conditions, such as system startup or external disturbances, without the need for a physical prototype.

* **[egidio2020__discreto]**: The paper validates its control strategy for a discrete-time switched affine system using a simulated DC-DC multicellular converter. Simulations demonstrate the system's startup, convergence to a limit cycle, and its performance under H₂ and H∞ control objectives.
* **[mohammed_benmiloud_2019]**: A simulated DC-DC three-cell power converter is used to demonstrate the local stabilization of a hybrid limit cycle. The authors use a hybrid Poincaré map approach and show 3D plots of the system's state converging to the desired cycle.
* **[Sanchez 2019]**: This study simulates a DC-DC boost converter to test its regularization techniques for practical stabilization. The simulations show the trade-offs between design parameters and switching frequency during transient and steady-state operation.
* **[Xu 2022]**: This paper uses simulations of a boost converter to demonstrate global exponential stability of a limit cycle under an H∞ control objective. The results show that the control strategy can effectively suppress disturbances and ensure the state trajectory follows the desired cycle.
* **[patino2010]**: The paper uses both simulation and experimental methods. In the simulation part, it models a Buck-Boost converter and a multilevel converter, demonstrating the control strategy's ability to minimize oscillations and follow a desired trajectory.

***

### **Experimental Validation**

This is the most rigorous form of validation, where control strategies are tested on physical hardware in a laboratory setting. It confirms that the theoretical models and simulation results hold true in a real-world environment, accounting for unmodeled dynamics, noise, and other practical limitations.

* **[Andrikopoulos 2013]**: The researchers use a Festo fluidic pneumatic artificial muscle (PAM) for experimental validation. They compare the performance of their proposed switching Model Predictive Control (SMPC) with a classical PID controller, showing the SMPC's superior accuracy and faster response for position control.
* **[SOLANO_SAENZ_Eduard_Hernando]**: The doctoral thesis presents the experimental implementation of its control strategies on a physical prototype. It uses a DE2 FPGA card for control and measures variables to validate the performance of the proposed methods on multi-cell converters. The experimental results are compared to simulations to confirm the validity of the models and control strategies in a real-world context.
* **[patino2010]**: The paper tests its predictive control approach on a physical Buck-Boost and a multilevel converter in a laboratory environment. The results from these experiments are compared to simulations, demonstrating the control law's effectiveness in both start-up and input supply variation tests.