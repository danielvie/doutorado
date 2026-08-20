## Referee Report — Abstract only (`article.tex:33`)

**Model:** Claude Opus 5.0 · **Scope:** abstract, checked against `GOAL.md`, `CONTEXT.md`, `research/novelty-review.md`, `research/springer-40313-template.md`, `results/metrics.tex`, and §§1–5 of the body.

**Overall:** The abstract is accurate, well-ordered, and correctly leads with the conditioner + certificate as the contribution (matches `GOAL.md:3`). Every number I could trace resolves correctly against `results/metrics.tex` and the body. I found no false statement. The issues below are omissions of hypotheses and scope that a referee will probe, not errors.

---

### Blockers

**None.** I checked each claim for correctness and found no overclaim, no unsupported number, and no first-ever/global claim (consistent with `GOAL.md:15`, `GOAL.md:33-34`). In particular, the closing sentence does *not* assert a nonlinear guarantee under active conditioning, which is the failure mode I was most alert to.

---

### Worthwhile fixes

**1. The local/global sentence is true but omits the one condition that makes it interesting.**
Anchor: *"The Lyapunov result covers the linearized family, and the nonlinear guarantee is local."*
The body is sharper (`article.tex:278`): the neighborhood is one where *"the conditioner never acts, $\beta=1$"*. So the only exact-nonlinear guarantee holds precisely where the paper's headline mechanism is inactive — and `GOAL.md:21` requires it be stated that way. As written, a reader can reasonably infer the local nonlinear result covers the conditioned loop in a non-trivial sense. Suggest: *"…and the nonlinear guarantee is local, in a neighborhood where conditioning is inactive."* (+6 words.)

**2. The certificate's hypothesis on $\Phi$ is inferable but not visible.**
Anchor: *"one quadratic Lyapunov function that contracts both endpoints certifies every sequence of conditioning factors."*
Since $\Phi$ is one endpoint, the abstract technically states the hypothesis, but the body flags it as a genuine restriction (`article.tex:276`: *"the certificate is available only for plants whose nominal cycle is already stable"*). Referees will ask whether the certificate presupposes an open-loop-stable cycle. Suggest adding *"when the nominal cycle map itself contracts in that norm"* to sentence 4 (+8 words).

**3. Prior-art attribution of the cycle model.**
Anchor: *"We obtain that model by exact augmented matrix-exponential propagation … and it reduces to the switched-actuator model as a special case."*
"We obtain that model" plus an unattributed definite article ("*the* switched-actuator model") lets an abstract-only reader credit the one-cycle model to this paper. `research/novelty-review.md:35,38` and `GOAL.md:33` are explicit that the fixed-period one-cycle model and the switching sensitivity are prior art (Marcolino; Patiño). The body handles this correctly (`article.tex:198,206,415`). Minimal repair: *"reduces to the published switched-actuator model"* (+1 word), or *"recovers the published sensitivity structure and reduces to…"*.

**4. Conditioning is made the grammatical agent of the settling speed-up.**
Anchor: *"Conditioning restores the assumed \si{3}{\micro\second} bound and still settles in 6 cycles, against 20 for a conservative law that never violates it."*
The speed advantage comes from the aggressive tuning ($R_n=0.001I_8$) that conditioning makes admissible, not from conditioning itself; the body states this correctly (`article.tex:385`, `article.tex:421`). Suggest making the closed loop the subject: *"Conditioning restores the assumed 3 µs bound, and the loop still settles in 6 cycles, against 20 for a conservative law that never violates it."* Also consider "enforces" over "restores" — the bound was never lost, compliance was.

**5. Simulation-only evidence is not signalled.**
Anchor: *"On a nine-interval DC–DC converter benchmark…"*
`GOAL.md:48` lists simulation-only validation as an accepted limitation, and the body says so twice (`article.tex:47`, `article.tex:417`). "Benchmark" alone does not carry it. Suggest *"In exact nonlinear simulation of a nine-interval DC–DC converter benchmark"* (+4 words).

**6. Journal-format items (`research/springer-40313-template.md:48`).**
- Word count is **~222**, inside the required 150–250 band — but that leaves only ~28 words for fixes 1–3 and 5 (~19 words). Trim candidate: *"which lets the state matrix and the affine term change together"* → *"for mode-dependent affine dynamics"* (−6).
- $\Phi$, $A_{\mathrm{cl}}$, $\beta$, and $N$ appear undefined. $A(\beta)=(1-\beta)\Phi+\beta A_{\mathrm{cl}}$ carries the contribution, so I would keep it, but consider naming the endpoints inline ("the nominal cycle matrix $\Phi$", "the raw closed-loop matrix $A_{\mathrm{cl}}$") — the appositive already does half of this.
- The abstract contains macros (`\MinimumRawDwell`, `\AppliedScheduleDwellBound`, `\ConditionedSettlingCycle`, `\ConservativeSettlingCycle`) and `\si{\micro\second}`. These compile, but the submission portal's plain-text abstract field will not resolve them; a hand-expanded plain-text copy will be needed at submission.
- Typography: `\MinimumRawDwell{}~\si{\micro\second}` renders `-43.045` with a text hyphen, not a minus sign. `\SI{\MinimumRawDwell}{\micro\second}` is used elsewhere (`article.tex:302,314,320`) and would fix sign glyph and spacing. Worth correcting at least in the abstract, where it is the only signed number.

---

### Optional polish

- *"or even reverse it"* — nearest noun antecedent is "the minimum dwell duration", not "a mode interval". Consider *"or even invert the interval"*.
- *"an aggressive law starting far from the trajectory"* — the law does not start anywhere; the plant state does. Consider *"an aggressive law started from a state far from the trajectory"*.
- *"requests a −43.045 µs dwell"* — the law requests offsets; the *resulting* dwell is negative. *"requests a schedule with a −43.045 µs dwell"* is more literal, at +3 words.
- *"We repair the requested action instead of redesigning the law"* — effective framing; "repair" may read as informal to some referees. Neutral alternative: "We correct the requested action". Purely stylistic.
- Title says "Mode-Dependent Switched-Affine Systems"; "mode-dependent" surfaces in the abstract only obliquely in sentence 5. Fix 6's proposed trim would also put the term in the abstract explicitly.

---

### Author decisions (no recommendation implied)

- Whether to include $\beta_{\min}=0.293978$ and the 3-of-100 active-conditioning count. It quantifies how rarely and how hard the conditioner bites, but costs words.
- Whether to state $\rho(\Phi)=0.999850$ or the 22009-cycle open-loop convergence. The body devotes a paragraph and a figure to it (`article.tex:387`, `fig:conditioned-trajectory`), and it doubles as evidence that the Prop. 2 hypothesis on $\Phi$ holds here — but it also exposes that the certified bound `0.999939` is set by the open-loop endpoint and is quantitatively near-vacuous (`article.tex:353` says this honestly). Including or omitting is defensible; omitting is not a misstatement.
- Whether *"a conservative law that never violates it"* should be scoped to this run. It is an empirical observation (minimum conservative dwell 15.502 µs), presented generically. The body uses the same framing at `article.tex:421`, so this is a consistency choice, not an error.

---

### Verified as correct (cross-checked, no action needed)

| Abstract claim | Source |
|---|---|
| $A(\beta)=(1-\beta)\Phi+\beta A_{\mathrm{cl}}$ | `article.tex:254`, algebra confirmed from `eq:raw-law` |
| "largest factor in $[0,1]$", direction / mode order / period preserved, $O(N)$, no solver | Prop. 1 and proof, `article.tex:241-248` |
| certificate covers *state-dependent* $\beta_k$ sequences | Prop. 2, `article.tex:267` |
| nine-interval benchmark | `\NominalIntervalCount{}` = 9 |
| −43.045 µs raw dwell; 3 µs applied bound | `\MinimumRawDwell`, `\AppliedScheduleDwellBound`; `article.tex:385` |
| settles in 6 vs 20 cycles | `\ConditionedSettlingCycle`, `\ConservativeSettlingCycle`; `tab:results` threshold definition at `article.tex:365` |
| "or even reverse it" (interval inversion) | `article.tex:385`, `fig:first-cycle-conditioning` |
| mode-dependent $A_{\bm u}$ *and* $\bm b_{\bm u}$ | `article.tex:288-300` |
| reduction to switched-actuator model | `article.tex:200-206` (body adds a sign-convention caveat) |
| no citations in abstract (journal requires none) | confirmed — no `\cite` in `article.tex:33` |
| 6 keywords (journal band 4–6) | `article.tex:35` |
