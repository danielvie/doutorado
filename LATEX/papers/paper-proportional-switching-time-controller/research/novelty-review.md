# Novelty review: fixed-period switching-instant feedback

## Bottom line

The current equation is a **strict dynamic generalization of Marcolino's model**: it permits mode-dependent state matrices and affine vectors, whereas Marcolino keeps one constant plant matrix and switches only actuator levels. However, the **core method is not globally new** within the reviewed primary literature: a fixed-period cycle with only the interior switching instants perturbed, a first-order one-cycle model

\[
e_{k+1}=\Phi e_k+\Gamma_\tau\delta\tau_k,
\]

and static discrete LQR feedback on that model were already presented by Marcolino, Galvão, and Kienitz for the narrower switched-actuator class. Patino, Riedinger, and Ruiz had earlier derived analytical switching-instant sensitivities for fixed-period mode-dependent cyclic switched systems and used them in online optimization. An earlier qualification manuscript by the author contains a switched-affine development and converter application, but it is unpublished and is not treated as citable prior literature. The relative extension over Marcolino is therefore valid, but must be distinguished from a claim of first switching-instant sensitivity for mode-dependent systems.

The most defensible novelty is therefore **not** “local periodic-orbit stabilization by one-cycle switching-time feedback.” It is the narrower constraint-handling layer:

1. uniform radial contraction of the complete switching-instant-offset vector to enforce every minimum dwell duration while retaining the fixed period and action direction; and
2. the associated local-model analysis: the raw-action admissible polyhedron, its invariant subset, and especially the common-Lyapunov certificate for the conditioned family
   \(A(\beta)=(1-\beta)\Phi+\beta A_{\mathrm{cl}}\), \(\beta\in[0,1]\).

No reviewed source discloses that complete conditioner-plus-certificate construction. This supports a claim of an **incremental constrained-control contribution**, not a first method for local orbit stabilization or switching-instant linearization.

## Scope and confidence

This is a defensibility review, not a proof of worldwide priority. It covers the original works cited in `references.bib`, relevant published primary literature available as repository PDFs, and one unpublished qualification manuscript used only as internal background. It does not include a systematic database, patent, or forward-citation search. Accordingly:

- confidence that the **core architecture is prior art**: high;
- confidence that the **specific uniform conditioner and its stability certificate are absent from the reviewed corpus**: high;
- confidence that they are globally first: low to moderate without a broader search.

## Novelty map

| Element | Assessment | Primary evidence |
|---|---|---|
| Stabilizing a desired limit cycle of a switched-affine system | Standard prior result | Benmiloud et al. design state-dependent switching surfaces and prove local asymptotic stability using a hybrid Poincaré map [S1, pp. 1–4]. Egidio et al. provide global limit-cycle results under mode-selection laws [S5; S6]. |
| Fixed nominal mode sequence and period; manipulate only \(N-1\) interior switching instants | Explicit prior art | Marcolino et al. impose \(t_N=t_{rN}=t_0+T\), define \(t_i=t_{ri}+\delta t_i\), \(i=1,\ldots,N-1\), and derive the adjacent dwell inequalities [S2, Secs. 2–3, eqs. (3), (8)–(12)]. |
| One-cycle first-order model in switching-instant offsets | Explicit prior art | Marcolino et al. obtain \(\hat e[k+1\mid k]=\Phi e[k]+\Gamma\delta t[k]\) [S2, eqs. (19), (27), (28)]. Patino et al. derive the state sensitivity to every switching instant, including the vector-field-jump term [S3, Prop. 7, eqs. (19)–(24)]. |
| Static proportional/DLQR law on the one-cycle model | Explicit prior art | Marcolino et al. use \(\delta t[k]=-Ke[k]\), with \(K\) from the discrete Riccati equation, as a direct comparator to MPC [S2, Sec. 5.2, eqs. (47)–(49)]. Calling the same map “proportional switching-time control” does not create methodological novelty. |
| One-cycle switching-instant model for changing switched-affine dynamics | Published sensitivity foundation plus unpublished internal precursor | Patino et al. derive the mode-dependent vector-field-jump sensitivity [S3, Prop. 7]. The author's unpublished qualification manuscript develops the cycle model and converter application [S4], but it is not citable prior literature. |
| Matrix-exponential/augmented-state derivation | Technical derivation, not a first sensitivity claim | Augmentation of affine converter dynamics and analytical switching-time sensitivities already appear in Patino et al. [S3, pp. 1261–1263]. The cleaner controller-ready derivation is useful, but should not be sold as the first mode-dependent switching sensitivity. |
| Dwell constraints as linear inequalities/polyhedra | Standard prior result | Marcolino et al. express all dwell bounds as \(L\delta t\le c\), formulate a convex QP, characterize feasibility by polyhedral projection, and use the maximal admissible terminal set under LQR [S2, Sec. 4, eqs. (38)–(44); Appendix A]. |
| Uniform scaling \(\delta\tau=\beta\delta\tau^{raw}\) with maximal feasible \(\beta\in[0,1]\) | Potentially novel in this corpus | Marcolino's DLQR comparator instead uses sequential actuator saturation; it may shift the final switching time, violates the raw fixed-period request, and diverges in the example [S2, Sec. 5.2, Algorithm 1, Table 4]. No reviewed source uses the proposed direction-preserving radial contraction. |
| Raw-action admissible set and maximal invariant subset | Defensible integration, but mathematically standard | The preimage of linear dwell inequalities under \(-Ke\) is immediately polyhedral, and invariant-set computation is standard constrained-control machinery already used by Marcolino et al. for their terminal set [S2, Sec. 4]. Novelty lies, if anywhere, in applying it explicitly to this no-optimizer conditioner. |
| Convex-segment/common-Lyapunov certificate for active conditioning | Strongest defensible analytical novelty | No reviewed source analyzes a state-dependent scalar attenuation of timing feedback as \((1-\beta)\Phi+\beta A_{cl}\) or proves stability for all attenuation sequences from endpoint LMIs. The argument uses standard quadratic Lyapunov tools [S7; S8], but their application to this conditioner appears new in the reviewed corpus. |
| LQR, guaranteed-cost, or \(H_\infty\) synthesis itself | Standard | These are established discrete-time and LMI methods; the cited Boyd et al. and Zhou et al. references are foundational sources [S7; S8]. A matched comparison can be useful evidence, but is not a controller-theory novelty. |

## What the decisive sources establish

### Marcolino, Galvão, and Kienitz: the core architecture already exists

This is the closest prior work and should control the novelty wording.

The paper fixes both cycle boundaries, perturbs only the \(N-1\) interior switching instants, and derives a cycle-sampled linear model from the current cycle error and the switching-time perturbation vector [S2, Secs. 2–3]. It then:

- repeats the model from cycle to cycle as its predictive model [S2, eq. (28)];
- imposes all minimum dwell constraints as linear inequalities coupling adjacent instant offsets [S2, eqs. (38)–(39)];
- designs a stabilizing terminal law \(\delta t=-Ke\) from an infinite-horizon LQR [S2, Sec. 4]; and
- separately simulates that same static DLQR law [S2, Sec. 5.2, eqs. (47)–(49)].

Therefore, neither the fixed-period coordinate choice, the cycle linearization, nor static LQR timing feedback is new.

The paper also identifies the exact unresolved issue that the present conditioner addresses: unconstrained DLQR timing requests can violate dwell bounds and even yield negative durations. Its actuator-side sequential saturation can move the final switching instant, and the illustrated closed loop diverges [S2, Sec. 5.2, Algorithm 1, Table 4]. Replacing that saturation with a fixed-period, direction-preserving feasible scaling is a meaningful difference.

### Unpublished qualification manuscript: internal precursor only

The author's qualification manuscript develops a switched-affine cycle model, timing-offset MPC, and the same converter class [S4]. Because that manuscript was not published, the paper does not cite it or present it as published prior art. It remains relevant internal provenance and prevents the present paper from mischaracterizing the development history.

The present paper instead grounds its public novelty comparison in Patiño's published mode-dependent sensitivity and Marcolino's published fixed-period switched-actuator model. The augmented matrix-exponential development is a controller-ready derivation and validation contribution, not a first switching-sensitivity claim.

### Patino, Riedinger, and Ruiz: switching-instant sensitivity is older

Patino et al. formulate cyclic operation with a fixed final period \(t_s=T_p\), optimize the interior switching instants, and derive analytical sensitivities of states at later switching events [S3, Secs. III–IV]. Proposition 7 gives, for an earlier switching instant \(t_j\), a propagated term containing \((A_j-A_{j+1})x(t_j)\) [S3, eqs. (19)–(24)]. In affine coordinates this is the same vector-field-jump structure recovered by the current \(\Gamma_{\tau,j}\).

Their online law is Gauss–Newton/predictive optimization, not static LQR, and they explicitly state that they do not provide a stability proof [S3, Sec. VII]. The current low-cost static implementation can therefore be contrasted with Patino, but the sensitivity formula and fixed-period switching-instant parametrization cannot be claimed as new.

### Benmiloud and Egidio: orbit stabilization is established, but by different actuators

Benmiloud et al. stabilize a predefined switched-affine limit cycle by designing state-dependent switching hypersurfaces. Stability is assessed through the Jacobian of a hybrid Poincaré map, and selected surfaces place its eigenvalues at zero [S1, Theorems 1–3]. This establishes local limit-cycle stabilization but does not use per-cycle timing-offset commands around a fixed schedule.

Egidio et al. study global asymptotic stabilization of limit cycles through state-dependent mode-selection laws in discrete time [S5] and continuous time [S6]. Their control variable is the active subsystem, not an offset vector for prescribed interior switching instants. These works define the broader prior-art field; they do not anticipate the proposed conditioner.

### Dwell-time literature

Albea Sanchez et al. guarantee positive dwell time through hybrid time or space regularization while practically stabilizing an operating-point neighborhood [S9]. This is distinct from preserving a prescribed periodic sequence and adjusting its interior instants. It does, however, show that “stability with dwell-time enforcement” is itself too broad a novelty claim.

## Standard results that should be presented as such

The paper should label the following as known machinery or direct specialization:

1. exact propagation of affine modes through augmented matrix exponentials;
2. the cycle anchor as a fixed point of the affine one-cycle map;
3. first-order differentiation of a product of mode transitions;
4. the vector-field jump produced by moving an internal switching instant;
5. reduction from \(N\) duration changes with zero sum to \(N-1\) interior instant offsets;
6. cycle-sampled state feedback and discrete LQR synthesis;
7. polyhedral dwell inequalities, maximal admissible/invariant sets, and LMI synthesis;
8. common quadratic Lyapunov functions and polytopic/\(H_\infty\) controller design.

A contribution can combine standard pieces in a useful way, but the novelty statement must identify the combination or new proof rather than relabeling the pieces.

## Defensible novelty claims

Subject to a broader literature search, the following wording is supportable:

> For a fixed-period switching schedule, we introduce a solver-free radial conditioner that applies the largest scalar multiple of a raw switching-instant feedback action compatible with all minimum dwell durations. We characterize the raw-action admissible region and show that, when the nominal and unconditioned one-cycle matrices share a quadratic Lyapunov function, every conditioned action is locally exponentially stable for arbitrary state-dependent scaling.

A still safer version is:

> The contribution is a constraint-handling and certification layer for existing one-cycle switching-time feedback: a direction-preserving feasible scaling, its admissible/invariant regions, and a common-Lyapunov stability test under active conditioning.

Secondary, case-study-level contributions may include:

- a compact augmented-state derivation specialized to general switched-affine mode sequences;
- a reproducible implementation on a three-cell converter;
- explicit numerical verification of linearization accuracy and nonlinear local convergence; and
- a controlled comparison of nominal and robust gains on the same timing-input model.

These should be called derivational, implementation, or validation contributions—not new stabilization theory.

## Claims to avoid

Do not claim:

- the first local stabilization of a switched-affine limit cycle;
- the first one-cycle/Poincaré linearization for switching-time control;
- the first use of switching-instant offsets with fixed period;
- the first static LQR/proportional switching-time controller;
- the first dwell-constrained periodic-trajectory controller;
- a new LQR, guaranteed-cost, or \(H_\infty\) design; or
- global stability of the nonlinear switched-affine plant from a certificate proved only for the local cycle model.

Also avoid presenting \(\mathcal C_\infty\) as the MPC feasibility region's novel replacement. It is more precisely the maximal subset on which the **particular raw static law** remains admissible without conditioning; MPC feasibility asks whether **some** admissible future input sequence exists and is generally different.

## Recommended positioning

The cleanest paper narrative is:

1. **Known foundation:** fixed-period one-cycle timing linearization and static feedback.
2. **Known limitation:** raw LQR can request infeasible coupled dwell durations; prior actuator saturation may destroy the period and stability.
3. **New object:** maximal direction-preserving scaling of the raw offset vector.
4. **New analysis:** explicit raw-action admissible region, invariant subset, and stability of all conditioned gains through a common Lyapunov certificate.
5. **Evidence, not novelty:** converter simulation and robust-gain comparison.

This positioning is narrower than the current contribution list but materially more defensible against the closest prior work.

## Sources reviewed

- **[S1]** M. Benmiloud, A. Benalia, M. Djemai, and M. Defoort, “On the Local Stabilization of Hybrid Limit Cycles in Switched Affine Systems,” *IEEE Transactions on Automatic Control*, 64(2), 841–846, 2019. DOI: [10.1109/TAC.2018.2841806](https://doi.org/10.1109/TAC.2018.2841806). Repository PDF: `research-material/literature/articles-control/[Benmiloud 2019] On the local Stabilization of Hybrid Limit Cycles.pdf`.
- **[S2]** M. H. Marcolino, R. K. H. Galvão, and K. H. Kienitz, “Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints,” *Journal of Control, Automation and Electrical Systems*, 32(1), 1–17, 2021. DOI: [10.1007/s40313-020-00667-9](https://doi.org/10.1007/s40313-020-00667-9). Repository PDF: `research-material/literature/prior-work/marcolino2020.pdf`.
- **[S3]** D. Patino, P. Riedinger, and F. Ruiz, “A Predictive Control Approach for DC–DC Power Converters and Cyclic Switched Systems,” *2010 IEEE International Conference on Industrial Technology*, 1259–1264, 2010. Repository PDF: `research-material/literature/articles-control/[Patino 2010] A predictive control approach for DC_DC power converters.pdf`.
- **[S4] Unpublished internal background, not cited in the paper:** D. Vieira, *Predictive Control of Switched Affine Systems Subjected to Dwell Time Constraints*, qualification manuscript, especially Chapter 4.
- **[S5]** L. N. Egidio, H. R. Daiha, and G. S. Deaecto, “Global Asymptotic Stability of Limit Cycle and \(H_2/H_\infty\) Performance of Discrete-Time Switched Affine Systems,” *Automatica*, 116, 108927, 2020. DOI: [10.1016/j.automatica.2020.108927](https://doi.org/10.1016/j.automatica.2020.108927). Repository PDF: `research-material/literature/articles-control/[Egidio 2020]__discreto Global Asymptoic stability of limit cycle.pdf`.
- **[S6]** L. N. Egidio, G. S. Deaecto, and J. C. Geromel, “Limit Cycle Global Asymptotic Stability of Continuous-Time Switched Affine Systems,” *IFAC-PapersOnLine*, 53(2), 6121–6126, 2020. DOI: [10.1016/j.ifacol.2020.12.1689](https://doi.org/10.1016/j.ifacol.2020.12.1689). Repository PDF: `research-material/literature/articles-control/[Egidio 2020]__continuo Limit cycle global asymptotic stability.pdf`.
- **[S7]** S. Boyd, L. El Ghaoui, E. Feron, and V. Balakrishnan, *Linear Matrix Inequalities in System and Control Theory*, SIAM, 1994. DOI: [10.1137/1.9781611970777](https://doi.org/10.1137/1.9781611970777).
- **[S8]** K. Zhou, J. C. Doyle, and K. Glover, *Robust and Optimal Control*, Prentice Hall, 1996.
- **[S9]** C. Albea Sanchez, G. Garcia, S. Hadjeras, W. P. M. H. Heemels, and L. Zaccarian, “Practical Stabilisation of Switched Affine Systems with Dwell-Time Guarantees,” *IEEE Transactions on Automatic Control*, 2019/2020. DOI: [10.1109/TAC.2019.2907381](https://doi.org/10.1109/TAC.2019.2907381). Repository PDF: `research-material/literature/articles-dwell-time/[Sanchez 2019] - Practical stabilisation of switched affine systems with dwell-time guarantees.pdf`.
