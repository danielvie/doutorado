# Research: Lyapunov references for dwell-conditioned scalar feedback attenuation

## Scope and manuscript context

I read the manuscript's conditioning section (`sec:conditioning`), Lyapunov/convex-optimization section (`sec:stability`), and `latex/references.bib` before searching. The relevant claim is the discrete-time cycle family
\[
 e_{k+1}=A(\beta_k)e_k,\qquad A(\beta)=A_0+\beta(A_1-A_0)=\Phi_x-\beta\Gamma_\tau K,
\]
where one state-dependent scalar \(\beta_k\in[0,1]\) multiplies the complete raw timing command to enforce coupled minimum dwell constraints. The manuscript seeks one \(P\succ0\) such that
\[
 P-A_i^\mathsf{T}PA_i\succeq\eta I,\quad i=0,1,
\]
and uses a Schur-complement block affine in \(\beta\) to cover the entire segment and arbitrary factor sequences. It correctly distinguishes this linearized certificate from a nonlinear large-error region-of-attraction guarantee.

The existing bibliography already contains `mason2004commonQuadratic`, `deOliveira1999lmiDiscrete`, and `olalla2009robustLqrPwm`; the other eight selected articles are not present. Searches used multiple angles (discrete-time saturation, convex-hull/sector LMIs, switched/polytopic common Lyapunov functions, and power-converter robust LMI control) with `workflow: none`. Primary PDFs/author manuscripts were fetched and inspected where available; publisher abstract pages were used only for the limited claims explicitly marked as abstract-level evidence.

## Compact comparison table

| Rank | Article (type) | Model and certificate | Closeness to this manuscript | BibTeX status |
|---:|---|---|---|---|
| 1 | Hu, Lin & Chen (2002), *Systems & Control Letters* (journal) | Discrete-time \(x^+=Ax+B\operatorname{sat}(Fx)\); common quadratic contractive ellipsoid, convex-hull vertices, Schur-complement LMIs | **Closest direct precedent:** state-dependent saturation represented by vertex feedback alternatives; one quadratic \(P\) checked at all vertices | New |
| 2 | Gomes da Silva Jr. & Tarbouriech (2001), *IEEE TAC* (journal) | Discrete-time componentwise saturation as \(A+B\operatorname{diag}(\alpha(x))F\); polytopic/ellipsoidal LMI certificate | Direct precedent for multiplicative state-dependent attenuation and vertex checks | New |
| 3 | Cao & Lin (2003), *Automatica* (journal) | Discrete-time saturation as a state-dependent convex combination; saturation-dependent \(P(\eta)\), pairwise vertex LMIs | Direct precedent for changing attenuation weights; constant-\(P\) case is especially relevant | New |
| 4 | Zhou (2013), *Systems & Control Letters* (journal) | Discrete-time nested saturation; compact convex hull and LMIs for local/global stability | Direct coupled/nested-saturation framework, but not a single scalar factor | New |
| 5 | Gomes da Silva Jr. & Tarbouriech (1999), *IEEE TAC* (journal) | Discrete-time saturation regions; polyhedral contractivity and polyhedral Lyapunov function | Foundational direct reference for separating feasibility/contractivity from convergence | New |
| 6 | Montagner et al. (2006), CDC (conference) | Continuous-time polytopic uncertain saturated plant; common-\(P\) and parameter-dependent \(P(\alpha)\) LMIs | Strong supporting framework for the common-vs-parameter-dependent SDP tradeoff | New |
| 7 | Gomes da Silva Jr., Tarbouriech & García (2003), *IEEE TAC* (journal) | Continuous-time first-order actuator with amplitude/rate saturation; convex-polytope quadratic LMIs | Coupled rate/amplitude limitation analogy; not discrete time | New |
| 8 | Mason, Sigalotti & Daafouz (2012), *Systems & Control Letters* (journal) | Discrete-time finite/polytopic switching; common, poly-quadratic, and parameter-dependent quadratic LMIs | Strong common-Lyapunov/switched-family framework; no saturation | New |
| 9 | de Oliveira, Geromel & Hsu (1999), *LAA* (journal) | Discrete-time robust/structural polytopic stability; LMI characterizations and parameter-dependent Lyapunov functions | Supporting vertex-LMI framework already cited in the manuscript | **Already present:** `deOliveira1999lmiDiscrete` |
| 10 | Olalla et al. (2009), *IEEE TIE* (journal) | Uncertain averaged PWM converter; polytopic model, common quadratic stability, robust LQR LMIs | Direct power-converter precedent for offline robust LMI certification | **Already present:** `olalla2009robustLqrPwm` |

## Findings

### 1. Direct precedent — auxiliary-feedback convex-hull criterion for a contractive ellipsoid

**Complete identity:** Tingshu Hu, Zongli Lin, and Ben M. Chen, “Analysis and design for discrete-time linear systems subject to actuator saturation,” *Systems & Control Letters*, 45(2), 97–112, 2002. DOI: [10.1016/S0167-6911(01)00168-2](https://doi.org/10.1016/S0167-6911(01)00168-2). Stable primary URL: [Elsevier DOI record](https://doi.org/10.1016/S0167-6911(01)00168-2); inspected primary proceedings text: [CDC PDF](http://congres.cran.univ-lorraine.fr/2001/CDC%202001/pdffiles/papers/877.pdf).

- **Publication type:** Peer-reviewed journal article; the inspected open PDF is the closely corresponding CDC proceedings version.
- **System setting:** Discrete-time linear plant \(x(k+1)=Ax(k)+B\operatorname{sat}(u(k))\), with \(u(k)=Fx(k)\) and standard componentwise saturation.
- **Exact saturation/conditioning model:** Saturation level is normalized to one. For an auxiliary \(H\), diagonal selectors \(D_i\) and \(D_i^-=I-D_i\) describe the channels represented by \(F\) versus \(H\). On \(L(H)=\{x:|h_i x|\le1\}\), \(\operatorname{sat}(Fx)\) is in the convex hull of \((D_iF+D_i^-H)x\); the corresponding vertex matrices are \(A+B(D_iF+D_i^-H)\).
- **Lyapunov/certificate method:** A common quadratic \(V=x^\mathsf{T}Px\) is used. Theorem 1 requires \((A+B(D_iF+D_i^-H))^\mathsf{T}P(A+B(D_iF+D_i^-H))-P\prec0\) at every selector vertex and \(E(P,\rho)\subseteq L(H)\). Convexity of the quadratic form gives contractivity of the actual saturated map; Schur complements and \(Q=P^{-1}\) yield LMIs.
- **Specific relevant result:** Vertex decrease under the convex-hull representation certifies a single contractive ellipsoid despite state-dependent saturation. This is the clearest direct precedent for treating the conditioner as a state-dependent gain and checking one quadratic certificate on a finite set of matrices.
- **Why close:** Discrete time; actuator saturation is an effective state-dependent attenuation; common quadratic function; convex hull; vertex LMIs.
- **Mismatch/limitation:** Channels switch between \(F\) and an auxiliary \(H\), not one scalar multiplying the entire action. The result is local to an ellipsoid and does not prove the manuscript's two-endpoint affine-segment argument or arbitrary state-dependent \(\beta_k\) sequence.
- **Support:** Direct evidence from the inspected primary PDF; **confidence high**.
- **Already in `latex/references.bib`:** No.
- **Candidate manuscript sentence:** “For discrete-time actuator saturation, a convex-hull representation of the saturated input and a common quadratic decrease inequality at its vertices provide an LMI-testable contractive ellipsoid [Hu, Lin, and Chen, 2002].”

### 2. Direct precedent — local stabilization with saturating controls

**Complete identity:** J. M. Gomes da Silva Jr. and Sophie Tarbouriech, “Local stabilization of discrete-time linear systems with saturating controls: an LMI-based approach,” *IEEE Transactions on Automatic Control*, 46(1), 119–125, 2001. DOI: [10.1109/9.898703](https://doi.org/10.1109/9.898703). Stable primary URL: [IEEE Xplore record](https://ieeexplore.ieee.org/document/898703); inspected primary proceedings text: [ACC PDF](http://congres.cran.univ-lorraine.fr/1998/ACC_98/pdffiles/papers/Vol1/WA04_4.pdf).

- **Publication type:** Peer-reviewed journal article; inspected open PDF is the earlier ACC version.
- **System setting:** Discrete-time \(x^+=Ax+Bu\), componentwise bounded input, saturating feedback \(u=\operatorname{sat}(Fx)\).
- **Exact saturation/conditioning model:** Each saturated channel is written as \(\operatorname{sat}(F_i x)=\alpha_i(x)F_i x\), with \(0<\alpha_i(x)\le1\). Thus \(x^+=(A+B\operatorname{diag}(\alpha(x))F)x\). Lower bounds on \(\alpha_i\) over a region produce \(2^m\) vertex matrices \(A_j=A+B\operatorname{diag}(\alpha_j)F\), and the state-dependent matrix lies in their convex hull.
- **Lyapunov/certificate method:** Sufficient LMIs in \(W\succ0\), \(Y\), with \(F=YW^{-1}\), make an ellipsoidal set contractile for the saturated system. The LMIs also impose a pole-region condition for the unsaturated closed loop and contain initial-set/saturation-region constraints.
- **Specific relevant result:** State-dependent multiplicative attenuation can be embedded in a local polytopic model and covered by one quadratic ellipsoidal certificate at its vertices.
- **Why close:** Discrete time, saturation as multiplicative state-dependent gain, convex-hull representation, quadratic/ellipsoidal LMI certificate.
- **Mismatch/limitation:** Attenuation factors are generally different per input channel and the result synthesizes the feedback. It is a local nonlinear saturated-system result, not a fixed-gain certificate for the manuscript's two scalar endpoints and continuum.
- **Support:** Direct primary PDF evidence; **confidence high** for the model/certificate, medium for transfer to the manuscript.
- **Already in `latex/references.bib`:** No.
- **Candidate manuscript sentence:** “State-dependent actuator attenuation can be embedded in a local polytopic model, for which a common quadratic ellipsoid can be certified by LMIs at the saturation vertices [Gomes da Silva Jr. and Tarbouriech, 2001].”

### 3. Direct precedent — saturation-dependent Lyapunov function

**Complete identity:** Yong-Yan Cao and Zongli Lin, “Stability analysis of discrete-time systems with actuator saturation by a saturation-dependent Lyapunov function,” *Automatica*, 39(7), 1235–1241, 2003. DOI: [10.1016/S0005-1098(03)00072-4](https://doi.org/10.1016/S0005-1098(03)00072-4). Stable primary URL: [Elsevier DOI record](https://doi.org/10.1016/S0005-1098(03)00072-4); inspected primary proceedings text: [CDC PDF](http://congres.cran.univ-lorraine.fr/2002/CDC_2002/pdffiles/papers/750_FrM05-2.pdf).

- **Publication type:** Peer-reviewed journal article; inspected open PDF is the corresponding CDC paper.
- **System setting:** Discrete-time \(x^+=Ax+B\sigma(u)\), fixed \(u=Fx\), unity componentwise saturation \(\sigma(u_i)=\operatorname{sign}(u_i)\min\{1,|u_i|\}\).
- **Exact saturation/conditioning model:** With auxiliary \(H\), the paper represents \(\sigma(Fx)\) over \(L(H)\) as \(\sum_i\eta_i(x)(E_iF+E_i^-H)x\), where \(\eta_i(x)\ge0\), \(\sum_i\eta_i=1\). Hence the closed-loop matrix is a state-dependent convex combination of vertex matrices.
- **Lyapunov/certificate method:** General certificate \(V=x^\mathsf{T}P(\eta(x))x\), with pairwise current/next vertex LMIs and a full-rank slack matrix. Setting all \(P_i\) equal recovers the common quadratic case. The optimization estimates a local domain of attraction.
- **Specific relevant result:** It proves decrease despite changing convex weights when pairwise vertex LMIs hold. The constant-\(P\) specialization is especially useful for explaining why a common quadratic function can cover state-dependent attenuation.
- **Why close:** Discrete time, effective state-dependent gain, convex hull, pairwise vertex LMIs, changing attenuation weights.
- **Mismatch/limitation:** The most general result uses parameter-dependent \(P(\eta)\) and a local attraction set. It does not prove the manuscript's exact two-endpoint Schur-complement interpolation.
- **Support:** Direct primary PDF evidence; **confidence high**.
- **Already in `latex/references.bib`:** No.
- **Candidate manuscript sentence:** “Actuator saturation can be represented by a state-dependent convex combination of linear closed-loop matrices, and pairwise vertex inequalities can enforce Lyapunov decrease despite changing saturation weights [Cao and Lin, 2003].”

### 4. Direct framework — nested discrete-time actuator saturation

**Complete identity:** Bin Zhou, “Analysis and design of discrete-time linear systems with nested actuator saturations,” *Systems & Control Letters*, 62(10), 871–879, 2013. DOI: [10.1016/j.sysconle.2013.06.012](https://doi.org/10.1016/j.sysconle.2013.06.012). Stable primary URLs: [Elsevier DOI record](https://doi.org/10.1016/j.sysconle.2013.06.012) and [ScienceDirect record](https://www.sciencedirect.com/science/article/pii/S0167691113001436).

- **Publication type:** Peer-reviewed journal article.
- **System setting:** Discrete-time nested-saturation system
  \[
  x^+=Ax+B\operatorname{sat}(F_1x+E_2\operatorname{sat}(F_2x+E_3\operatorname{sat}(\cdots+E_p\operatorname{sat}(F_px)\cdots))).
  \]
- **Exact saturation/conditioning model:** Standard vector saturation is recursively composed through the feedback layers; the unsaturated aggregate feedback is \(F=F_1+E_2F_2+(E_2E_3)F_3+\cdots+(\prod_{i=2}^pE_i)F_p\). The article introduces a compact convex-hull representation of the nested nonlinearity.
- **Lyapunov/certificate method:** Sufficient LMI conditions test local and global stability; domain-of-attraction estimation and gain design are formulated as LMI optimization problems. Additional slack variables reduce conservatism.
- **Specific relevant result:** Coupled/nested attenuation can be treated as a structured convex-hull nonlinearity rather than independent clipping, with LMI stability tests.
- **Why close:** Discrete time, coupled saturation layers, convex hull, LMIs, state-dependent attenuation.
- **Mismatch/limitation:** It has several nested gains, not one scalar multiplying the whole timing action, and does not establish the manuscript's two-endpoint proof. Direct `fetch_content` of the ScienceDirect page returned HTTP 403; the publisher's indexed full-text/abstract extraction and DOI metadata were inspected.
- **Support:** Publisher extraction plus DOI metadata; **confidence medium-high**.
- **Already in `latex/references.bib`:** No.
- **Candidate manuscript sentence:** “Nested actuator-saturation analyses likewise use compact convex-hull representations and LMI stability tests for coupled state-dependent attenuation layers [Zhou, 2013].”

### 5. Supporting direct precedent — polyhedral saturated-system regions

**Complete identity:** João Manoel Gomes da Silva Jr. and Sophie Tarbouriech, “Polyhedral regions of local stability for linear discrete-time systems with saturating controls,” *IEEE Transactions on Automatic Control*, 44(11), 2081–2085, 1999. DOI: [10.1109/9.802920](https://doi.org/10.1109/9.802920). Stable primary URLs: [IEEE Xplore](https://ieeexplore.ieee.org/document/802920/) and [UFRGS record](https://lume.ufrgs.br/handle/10183/27562).

- **Publication type:** Peer-reviewed journal note.
- **System setting/model:** Discrete-time saturated state feedback; state space is divided into saturation regions, each represented by a linear system with an additive saturation-induced disturbance. Polyhedra are written as \(S(G;w)=\{x:Gx\le w\}\).
- **Lyapunov/certificate method:** A necessary-and-sufficient contractivity condition is given for compact convex polyhedra. A strictly decreasing polyhedral Lyapunov function follows, and linear programming computes homothetic local stability-region expansions.
- **Specific relevant result:** It supports the manuscript's distinction between current-cycle schedule/admissibility regions and a convergence certificate: feasibility alone is not stability.
- **Why close:** Foundational discrete-time saturated-feedback stability-region and Lyapunov reference.
- **Mismatch/limitation:** Polyhedral rather than quadratic; no affine two-endpoint matrix family or endpoint SDP. The raw repository bitstream fetch failed, so the indexed primary repository/IEEE text was used for theorem/abstract inspection.
- **Support:** Direct indexed primary text; **confidence medium-high**.
- **Already in `latex/references.bib`:** No.
- **Candidate manuscript sentence:** “A contractive admissible region is distinct from mere schedule feasibility; saturation-region analysis can associate a decreasing Lyapunov function with an invariant polyhedron [Gomes da Silva Jr. and Tarbouriech, 1999].”

### 6. Supporting framework — robust saturated systems with polytopic uncertainty

**Complete identity:** Vinícius F. Montagner, Pedro L. D. Peres, Sophie Tarbouriech, and Isabelle Queinnec, “Improved Estimation of Stability Regions for Uncertain Linear Systems with Saturating Actuators: an LMI-based Approach,” in *Proceedings of the 45th IEEE Conference on Decision and Control (CDC 2006)*, San Diego, CA, 2006, pp. 5429–5434. DOI: [10.1109/CDC.2006.376839](https://doi.org/10.1109/CDC.2006.376839). Stable primary URLs: [IEEE DOI](https://doi.org/10.1109/CDC.2006.376839) and [open CDC PDF](http://congres.cran.univ-lorraine.fr/2006/IEEE%20CSS%202006/data/papers/1066.pdf).

- **Publication type:** Peer-reviewed conference article.
- **System setting:** Continuous-time uncertain \(\dot x=A(\alpha)x+B(\alpha)u\), with \((A(\alpha),B(\alpha))\) in a unit-simplex polytope and saturated state feedback \(u=\operatorname{sat}(Kx)\).
- **Exact saturation/conditioning model:** Componentwise amplitude saturation is rewritten as a decentralized dead-zone \(\psi(Kx)=Kx-\operatorname{sat}(Kx)\), satisfying a modified sector condition. The system matrices depend affinely on the uncertainty parameter \(\alpha\).
- **Lyapunov/certificate method:** A common quadratic \(W^{-1}\) with auxiliary \(Y,S\) is certified by vertex LMIs (8)–(9), yielding an ellipsoidal robust asymptotic-stability region. An affine parameter-dependent \(W(\alpha)=\sum_j\alpha_jW_j\) is treated by parameter-dependent sector variables and Pólya-theorem LMI relaxations (Theorem 2, (13)–(16)).
- **Specific relevant result:** It explicitly compares a common quadratic certificate with less-conservative parameter-dependent alternatives in a saturation problem. This supports the manuscript's fixed-gain common-\(P\) SDP as a deliberate sufficient certificate, while identifying a possible future relaxation.
- **Why close:** Saturation-as-dead-zone/sector, polytopic uncertainty, quadratic Lyapunov functions, vertex LMIs, and convex optimization.
- **Mismatch/limitation:** Continuous time and polytopic uncertainty, not a state-dependent scalar action factor; it does not prove the discrete-time endpoint segment or arbitrary \(\beta_k\) sequence. The source assumes robust stability of the unsaturated closed loop for the main local test.
- **Support:** Direct primary CDC PDF; **confidence high**.
- **Already in `latex/references.bib`:** No.
- **Candidate manuscript sentence:** “For saturated systems with polytopic uncertainty, common quadratic vertex LMIs are a convex but potentially conservative alternative to parameter-dependent Lyapunov relaxations [Montagner et al., 2006].”

### 7. Supporting framework — coupled amplitude/rate actuator saturation

**Complete identity:** João Manoel Gomes da Silva Jr., Sophie Tarbouriech, and Germain García, “Local stabilization of linear systems under amplitude and rate saturating actuators,” *IEEE Transactions on Automatic Control*, 48(5), 842–847, 2003. DOI: [10.1109/TAC.2003.811265](https://doi.org/10.1109/TAC.2003.811265). Stable primary URLs: [IEEE Xplore](https://ieeexplore.ieee.org/document/1198611) and inspected corresponding [CDC PDF](http://congres.cran.univ-lorraine.fr/2000/CDC%202000/PDF/AUTHOR/CD009206.PDF).

- **Publication type:** Peer-reviewed journal article; inspected open PDF is the corresponding CDC version.
- **System setting/model:** Continuous-time \(\dot x=Ax+Bu\) with a first-order actuator state \(u\) subject to both position/amplitude and rate limits; augmented state \(z=[x^\mathsf{T},u^\mathsf{T}]^\mathsf{T}\).
- **Exact saturation/conditioning model:** \(\dot u_i=\operatorname{sat}_{r_i}(\tau_i[-u_i+\operatorname{sat}_{p_i}(v_i)])\), \(v=K_xx+K_uu\). State-dependent attenuation factors for the two limiters are lower-bounded over a prescribed region; the augmented matrices form convex polytopes.
- **Lyapunov/certificate method:** Quadratic \(V=z^\mathsf{T}W^{-1}z\); vertex inequalities, ellipsoid containment in amplitude/rate regions, and pole-region LMIs. After fixing lower-bound parameters, iterative convex LMI problems compute the gain and certified region.
- **Specific relevant result:** Coupled rate and magnitude limits can be treated through multiple state-dependent factors and one quadratic certificate over a polytope. This is a useful analogy for coupled minimum-dwell inequalities.
- **Why close:** Coupled constraints, state-dependent nonlinear gains, convex-polytopic representation, quadratic/LMI stability.
- **Mismatch/limitation:** Continuous time with actuator dynamics and separate attenuation factors, not the manuscript's discrete-time one-scalar timing action. No claim about the manuscript's endpoint argument.
- **Support:** Direct primary CDC PDF and DOI metadata; **confidence high** for the framework, medium for transfer.
- **Already in `latex/references.bib`:** No.
- **Candidate manuscript sentence:** “Coupled amplitude/rate limitations have been handled by bounding state-dependent saturation factors and checking a common quadratic certificate over a convex polytope [Gomes da Silva Jr., Tarbouriech, and García, 2003].”

### 8. Supporting framework — common versus parameter-dependent quadratic switched stability

**Complete identity:** Paolo Mason, Mario Sigalotti, and Jamal Daafouz, “Comparison between classes of state-quadratic Lyapunov functions for discrete-time linear polytopic and switched systems,” *Systems & Control Letters*, 61(11), 1062–1068, 2012. DOI: [10.1016/j.sysconle.2012.07.010](https://doi.org/10.1016/j.sysconle.2012.07.010). Stable primary URLs: [Elsevier DOI](https://doi.org/10.1016/j.sysconle.2012.07.010) and [HAL author manuscript](https://inria.hal.science/inria-00629245/document).

- **Publication type:** Peer-reviewed journal article.
- **System setting/model:** Discrete-time \(x(k+1)=A_{\xi(k)}x(k)\), with finite or convex-polytopic mode set; arbitrary switching and bounded parameter-rate variation are considered.
- **Lyapunov/certificate method:** The paper compares static/common quadratic, parameter-dependent, parameter-and-time-dependent, and poly-quadratic functions. For a finite family, Proposition 4 gives finite LMIs \(P_i\succ0\) and \(A_i^\mathsf{T}P_jA_i-P_i\preceq-\alpha_0I\) for every current/next mode pair. Theorem 6 establishes equivalence among several quadratic criteria under a nondegeneracy condition; Theorem 8 treats bounded parameter variation.
- **Specific relevant result:** It provides the formal switched-family context for a sequence-independent common quadratic certificate and makes clear that parameter-dependent functions can be less conservative. The manuscript's common \(P\) is a stronger restriction than the article's poly-quadratic conditions.
- **Why close:** Discrete time, arbitrary switching, convex polytopes, quadratic Lyapunov functions, and finite LMIs.
- **Mismatch/limitation:** No actuator saturation, dwell feasibility, state-dependent attenuation, or converter. It does not claim to prove the manuscript's particular Schur-complement interpolation; that remains the manuscript's own argument.
- **Support:** Direct HAL author-manuscript theorem text and DOI metadata; **confidence high**.
- **Already in `latex/references.bib`:** No; `mason2004commonQuadratic` is a different article.
- **Candidate manuscript sentence:** “Common and parameter-dependent quadratic Lyapunov functions are standard alternatives for discrete-time polytopic/switched families; the common choice is sequence independent but can be conservative [Mason, Sigalotti, and Daafouz, 2012].”

### 9. Supporting framework — discrete-time robust/structural LMI stability

**Complete identity:** Maurício C. de Oliveira, José C. Geromel, and Liu Hsu, “LMI characterization of structural and robust stability: the discrete-time case,” *Linear Algebra and its Applications*, 296(1–3), 27–38, 1999. DOI: [10.1016/S0024-3795(99)00086-5](https://doi.org/10.1016/S0024-3795(99)00086-5). Stable primary URL: [Elsevier DOI record](https://doi.org/10.1016/S0024-3795(99)00086-5).

- **Publication type:** Peer-reviewed journal article.
- **System setting/model:** Discrete-time robust/structural stability with uncertain system matrices (including polytopic/structured uncertainty). The publisher abstract describes discrete-time extensions of robust-stability conditions and applications to \(D\)-stability and diagonal structured uncertainty.
- **Lyapunov/certificate method:** The article formulates conditions as LMIs and constructs parameter-dependent Lyapunov functions; the abstract explicitly contrasts the sharper parameter-dependent approach with the simultaneous/common stability approach. The common quadratic/simultaneous condition is the conservative special case relevant to the manuscript's fixed \(P\) SDP.
- **Specific relevant result:** It is a foundational source for using vertex/structured LMI conditions and for explaining why a common quadratic certificate is a sufficient but potentially conservative offline test, with parameter-dependent alternatives available.
- **Why close:** Discrete time, robust/polytopic uncertainty, LMI characterization, common versus parameter-dependent Lyapunov functions.
- **Mismatch/limitation:** No actuator saturation, state-dependent scalar gain, dwell constraints, or converter; it does not establish the manuscript's two-endpoint affine interpolation or arbitrary \(\beta_k\) theorem. Direct fetch of the ScienceDirect page returned HTTP 403; claims here are limited to the publisher abstract and verified bibliographic metadata.
- **Support:** Primary publisher abstract via DOI/search extraction; **confidence medium** for theorem-level detail, high for bibliographic identity and the abstract-level method claim.
- **Already in `latex/references.bib`:** Yes, `deOliveira1999lmiDiscrete`.
- **Candidate manuscript sentence:** “The endpoint SDP is a common-quadratic special case of broader discrete-time robust LMI characterizations, while parameter-dependent Lyapunov functions can reduce conservatism [de Oliveira, Geromel, and Hsu, 1999].”

### 10. Supporting application framework — robust LQR for PWM converters

**Complete identity:** Carlos Olalla, Ramon Leyva, Abdelali El Aroudi, and Isabelle Queinnec, “Robust LQR Control for PWM Converters: An LMI Approach,” *IEEE Transactions on Industrial Electronics*, 56(7), 2548–2558, 2009. DOI: [10.1109/TIE.2009.2017556](https://doi.org/10.1109/TIE.2009.2017556). Stable primary URLs: [IEEE Xplore record](https://ieeexplore.ieee.org/abstract/document/4909006/) and inspected author manuscript [PDF](https://homepages.laas.fr/queinnec/PDFpublis/IEEE_IndusElec2009_PWMconverters.pdf).

- **Publication type:** Peer-reviewed journal article.
- **System setting/model:** Averaged/linearized PWM buck and boost converter models with uncertain parameters. For the buck example, load and line voltage are uncertain; for the boost example, operating duty-cycle/load-related variables are embedded in a relaxed polytopic parameter model. The converter also has duty-cycle saturation/nonlinearity in the physical switched implementation, although the robust LMI certificate is for the linearized/averaged model.
- **Exact conditioning/uncertainty model:** The paper represents \([A(p),B_u(p)]\) as a convex hull of vertex matrices for bounded parameters. It designs state feedback \(\tilde u=K\tilde x\) and uses the LMI formulation of the LQR problem; a standard change of variables \(Y=KP\) and Schur complement produce convex constraints. At the vertices, a single \(P\) satisfies \(A_i^\mathsf{T}P+PA_i\prec0\) (continuous-time quadratic stability), and the robust LQR objective is bounded across all vertices.
- **Lyapunov/certificate method:** Common quadratic stability at polytopic vertices plus an LMI guaranteed-cost/LQR formulation; the paper explicitly states that the resulting buck controller is quadratically stable for arbitrarily fast changes of uncertain parameters. Simulations and a 100-W boost-converter prototype compare robust and nominal LQR under load/line perturbations.
- **Specific relevant result:** This is the closest application-level source for the manuscript's converter/SDP narrative: offline convex LMI certification over a finite vertex set, with one quadratic matrix covering parameter changes, followed by exact switched-converter validation. It supports citing the power-electronics precedent without implying that it certifies dwell-conditioned timing feedback.
- **Why close:** Same broad converter domain, offline LMI design, polytopic uncertainty, common quadratic Lyapunov certificate, and experimental validation.
- **Mismatch/limitation:** Continuous-time averaged/linearized converter models, not the manuscript's discrete cycle-to-cycle map; uncertainty parameters are not a state-dependent scalar action factor; duty-cycle saturation is not the manuscript's coupled minimum-dwell conditioner. The article does not prove the manuscript's endpoint argument or nonlinear timing-feedback region of attraction.
- **Support:** Direct author PDF inspected (including the polytopic model, vertex quadratic-stability inequality, LMI LQR formulation, and experimental section); **confidence high**.
- **Already in `latex/references.bib`:** Yes, `olalla2009robustLqrPwm`.
- **Candidate manuscript sentence:** “Robust LMI/LQR design has also been applied to PWM converters by modeling parameter uncertainty polytopically and imposing one quadratic stability certificate at the model vertices [Olalla et al., 2009].”

## Contradictions and qualification of the analogy

No source claims that pointwise Schur stability of every possible matrix is enough for arbitrary state-dependent switching. The closest papers use sufficient local certificates and, where applicable, convex-hull/vertex conditions. The selected sources differ in important ways:

1. Hu–Lin–Chen, Gomes da Silva–Tarbouriech, Cao–Lin, and Zhou are direct actuator-saturation precedents, but their saturation vertices are channel-wise or nested rather than one scalar factor multiplying the full timing action.
2. Montagner et al. and Gomes da Silva–Tarbouriech–García use continuous-time models, so their quadratic inequalities are not the manuscript's discrete-time \(P-A^\mathsf{T}PA\) inequalities.
3. Mason et al. and de Oliveira et al. supply switched/polytopic LMI frameworks but do not model saturation or dwell conditioning.
4. Olalla et al. supply the power-converter application precedent but certify an averaged/linearized uncertain plant, not the exact nonlinear timing conditioner.

No selected source proves the manuscript's exact endpoint-only Schur-complement argument. The correct claim is that these papers support the modeling and certificate framework; the manuscript's two-endpoint interpolation and arbitrary state-dependent \(\beta_k\) result should remain presented as its own derivation.

## Synthesis: strongest references

The best 3–5 references are:

1. **Hu, Lin & Chen (2002)** — closest direct match to discrete-time actuator saturation, convex-hull state-dependent gain, common quadratic ellipsoid, vertex LMIs, and Schur complements.
2. **Gomes da Silva Jr. & Tarbouriech (2001)** — foundational discrete-time polytopic representation of saturation as multiplicative state-dependent channel gains with a quadratic ellipsoidal LMI certificate.
3. **Cao & Lin (2003)** — strongest precedent for attenuation severity depending on the state and for Lyapunov decrease under changing current/next convex weights; cite its constant-\(P\) specialization, not as an exact precedent for the manuscript's endpoint proof.
4. **Mason, Sigalotti & Daafouz (2012)** — best common/parameter-dependent quadratic switched-family framework for explaining arbitrary factor sequences and conservatism of common \(P\).
5. **Olalla et al. (2009)** — best power-converter application precedent for offline vertex LMI/quadratic certification and experimental validation.

For coupled dwell constraints specifically, add **Gomes da Silva Jr., Tarbouriech & García (2003)** as a supporting analogy for amplitude/rate limits, and **Zhou (2013)** for nested discrete-time attenuation.

## Recommended citation placement

- **Introduction:** Hu–Lin–Chen (2002), Gomes da Silva Jr.–Tarbouriech (2001), Cao–Lin (2003) after the statement that actuator saturation is often represented as a nonlinear/state-dependent gain and analyzed with convex-hull or sector methods. Cite Gomes da Silva Jr.–Tarbouriech (1999) when distinguishing stability-region/contractivity analysis from mere input feasibility.
- **Conditioned-family/Common-\(P\) subsection:** Hu–Lin–Chen (2002), Gomes da Silva Jr.–Tarbouriech (2001), Cao–Lin (2003), Zhou (2013), and Mason et al. (2012). Explicitly say these are precedents for convex-hull/state-dependent attenuation and common or parameter-dependent quadratic certificates; do not say any proves the manuscript's exact two-endpoint result.
- **SDP subsection:** Montagner et al. (2006), de Oliveira–Geromel–Hsu (1999), Mason et al. (2012), and Hu–Lin–Chen (2002). Use them to motivate vertex LMIs, common versus parameter-dependent functions, and conservative-but-convex offline certification.
- **Discussion:** Gomes da Silva Jr.–Tarbouriech–García (2003) for coupled amplitude/rate limitations; Olalla et al. (2009) for converter-specific robust LMI practice; Gomes da Silva Jr. & Tarbouriech (1999) for invariant/contractive regions and the distinction between feasibility and convergence.
- **Avoid:** Do not cite the saturation papers as evidence of global nonlinear convergence of the manuscript's exact timing-feedback plant. The manuscript's own caveat about the linearized model and local nonlinear validity is necessary.

## Candidate BibTeX entries

The following entries are copied/reconstructed from verified DOI/publisher or primary-PDF metadata. They are candidates only; the manuscript bibliography was not edited.

```bibtex
@article{huLinChen2002actuatorSaturation,
  author  = {Hu, Tingshu and Lin, Zongli and Chen, Ben M.},
  title   = {Analysis and Design for Discrete-Time Linear Systems Subject to Actuator Saturation},
  journal = {Systems \& Control Letters},
  volume  = {45},
  number  = {2},
  pages   = {97--112},
  year    = {2002},
  doi     = {10.1016/S0167-6911(01)00168-2}
}

@article{gomesDaSilva2001localSaturation,
  author  = {Gomes da Silva Jr., J. M. and Tarbouriech, Sophie},
  title   = {Local Stabilization of Discrete-Time Linear Systems with Saturating Controls: An LMI-Based Approach},
  journal = {IEEE Transactions on Automatic Control},
  volume  = {46},
  number  = {1},
  pages   = {119--125},
  year    = {2001},
  doi     = {10.1109/9.898703}
}

@article{caoLin2003saturationDependent,
  author  = {Cao, Yong-Yan and Lin, Zongli},
  title   = {Stability Analysis of Discrete-Time Systems with Actuator Saturation by a Saturation-Dependent Lyapunov Function},
  journal = {Automatica},
  volume  = {39},
  number  = {7},
  pages   = {1235--1241},
  year    = {2003},
  doi     = {10.1016/S0005-1098(03)00072-4}
}

@article{zhou2013nestedSaturation,
  author  = {Zhou, Bin},
  title   = {Analysis and Design of Discrete-Time Linear Systems with Nested Actuator Saturations},
  journal = {Systems \& Control Letters},
  volume  = {62},
  number  = {10},
  pages   = {871--879},
  year    = {2013},
  doi     = {10.1016/j.sysconle.2013.06.012}
}

@article{gomesDaSilva1999polyhedralSaturation,
  author  = {Gomes da Silva Jr., Joao Manoel and Tarbouriech, Sophie},
  title   = {Polyhedral Regions of Local Stability for Linear Discrete-Time Systems with Saturating Controls},
  journal = {IEEE Transactions on Automatic Control},
  volume  = {44},
  number  = {11},
  pages   = {2081--2085},
  year    = {1999},
  doi     = {10.1109/9.802920}
}

@inproceedings{montagner2006saturatingActuators,
  author    = {Montagner, Vin{\'\i}cius F. and Peres, Pedro L. D. and Tarbouriech, Sophie and Queinnec, Isabelle},
  title     = {Improved Estimation of Stability Regions for Uncertain Linear Systems with Saturating Actuators: An LMI-Based Approach},
  booktitle = {Proceedings of the 45th IEEE Conference on Decision and Control},
  pages     = {5429--5434},
  year      = {2006},
  publisher = {IEEE},
  doi       = {10.1109/CDC.2006.376839}
}

@article{gomesDaSilva2003amplitudeRate,
  author  = {Gomes da Silva Jr., Joao Manoel and Tarbouriech, Sophie and Garcia, Germain},
  title   = {Local Stabilization of Linear Systems under Amplitude and Rate Saturating Actuators},
  journal = {IEEE Transactions on Automatic Control},
  volume  = {48},
  number  = {5},
  pages   = {842--847},
  year    = {2003},
  doi     = {10.1109/TAC.2003.811265}
}

@article{mason2012quadraticSwitched,
  author  = {Mason, Paolo and Sigalotti, Mario and Daafouz, Jamal},
  title   = {Comparison between Classes of State-Quadratic Lyapunov Functions for Discrete-Time Linear Polytopic and Switched Systems},
  journal = {Systems \& Control Letters},
  volume  = {61},
  number  = {11},
  pages   = {1062--1068},
  year    = {2012},
  doi     = {10.1016/j.sysconle.2012.07.010}
}

@article{deOliveira1999lmiDiscrete,
  author  = {de Oliveira, Maur{\'\i}cio C. and Geromel, Jos{\'e} C. and Hsu, Liu},
  title   = {LMI Characterization of Structural and Robust Stability: The Discrete-Time Case},
  journal = {Linear Algebra and its Applications},
  volume  = {296},
  number  = {1--3},
  pages   = {27--38},
  year    = {1999},
  doi     = {10.1016/S0024-3795(99)00086-5}
}

@article{olalla2009robustLqrPwm,
  author  = {Olalla, Carlos and Leyva, Ramon and El Aroudi, Abdelali and Queinnec, Isabelle},
  title   = {Robust LQR Control for PWM Converters: An LMI Approach},
  journal = {IEEE Transactions on Industrial Electronics},
  volume  = {56},
  number  = {7},
  pages   = {2548--2558},
  year    = {2009},
  doi     = {10.1109/TIE.2009.2017556}
}
```

## Unresolved evidence gaps

1. The selected direct saturation papers analyze channel-wise, nested, or rate/amplitude saturation; none found in this run has the exact discrete-time model “one scalar \(\beta(e)\) multiplies every feedback/timing component while coupled dwell inequalities determine \(\beta\)”.
2. No selected paper proves the manuscript's exact endpoint-only Schur-complement interpolation for \(A(\beta)=A_0+\beta(A_1-A_0)\). That claim should remain attributed only to the manuscript's own proof.
3. Most saturation results are local region-of-attraction/contractivity results. They do not replace the manuscript's explicit caveat that its common-\(P\) theorem concerns the linearized cycle map, not the exact nonlinear plant for arbitrary errors.
4. The selected converter reference (Olalla et al.) is based on averaged/linearized continuous-time models and polytopic parameter uncertainty; it does not certify switching-time timing feedback, dwell feasibility, timer quantization, delays, or nonlinear duty-cycle behavior outside the model region.
5. The direct ScienceDirect fetches for Zhou (2013) and de Oliveira et al. (1999) returned HTTP 403; the reported claims for Zhou are supported by the publisher's indexed full-text/abstract extraction, while de Oliveira claims are deliberately limited to the publisher abstract and verified metadata.
6. The raw UFRGS bitstream for Gomes da Silva Jr. & Tarbouriech (1999) was unavailable to the fetcher; the repository/IEEE indexed primary text was inspected. A local copy should be checked manually before quoting any exact theorem numbering.
7. Numerical certificate claims in the manuscript remain independent of these references and should continue to be verified by recomputing the endpoint eigenvalue margins, as the manuscript already does.

## Sources

### Kept

- [Hu, Lin & Chen, DOI](https://doi.org/10.1016/S0167-6911(01)00168-2) and [CDC primary PDF](http://congres.cran.univ-lorraine.fr/2001/CDC%202001/pdffiles/papers/877.pdf) — closest discrete-time convex-hull/common-quadratic saturation result.
- [Gomes da Silva Jr. & Tarbouriech, DOI](https://doi.org/10.1109/9.898703) and [primary PDF](http://congres.cran.univ-lorraine.fr/1998/ACC_98/pdffiles/papers/Vol1/WA04_4.pdf) — multiplicative state-dependent saturation and vertex LMIs.
- [Cao & Lin, DOI](https://doi.org/10.1016/S0005-1098(03)00072-4) and [CDC primary PDF](http://congres.cran.univ-lorraine.fr/2002/CDC_2002/pdffiles/papers/750_FrM05-2.pdf) — saturation-dependent Lyapunov function and pairwise vertex LMIs.
- [Zhou, DOI](https://doi.org/10.1016/j.sysconle.2013.06.012) — nested discrete-time saturation and compact convex hull.
- [Gomes da Silva Jr. & Tarbouriech, DOI](https://doi.org/10.1109/9.802920) — foundational polyhedral contractivity under saturation.
- [Montagner et al., DOI](https://doi.org/10.1109/CDC.2006.376839) and [CDC primary PDF](http://congres.cran.univ-lorraine.fr/2006/IEEE%20CSS%202006/data/papers/1066.pdf) — common and parameter-dependent robust saturation LMIs.
- [Gomes da Silva Jr. et al., DOI](https://doi.org/10.1109/TAC.2003.811265) and [CDC primary PDF](http://congres.cran.univ-lorraine.fr/2000/CDC%202000/PDF/AUTHOR/CD009206.PDF) — coupled amplitude/rate saturation.
- [Mason et al., DOI](https://doi.org/10.1016/j.sysconle.2012.07.010) and [HAL primary manuscript](https://inria.hal.science/inria-00629245/document) — common/poly-quadratic switched-family results.
- [de Oliveira et al., DOI](https://doi.org/10.1016/S0024-3795(99)00086-5) — foundational discrete robust/structural LMI framework.
- [Olalla et al., DOI](https://doi.org/10.1109/TIE.2009.2017556) and [author primary PDF](https://homepages.laas.fr/queinnec/PDFpublis/IEEE_IndusElec2009_PWMconverters.pdf) — converter polytopic model, vertex quadratic stability, robust LQR LMIs, experiment.

### Rejected or deprioritized

Search snippets, secondary citation pages, non-peer-reviewed preprints, books, and articles whose principal result concerned MPC, general switched-affine control, or unrelated converter optimization were not counted among the ten. They were used only for discovery and not as evidence for theorem-level claims.

## Next steps

Before submission, manually check the final journal versions of the first three direct precedents against the DOI records, then add the selected BibTeX entries and place citations as recommended above. No manuscript or bibliography files were edited by this review.
