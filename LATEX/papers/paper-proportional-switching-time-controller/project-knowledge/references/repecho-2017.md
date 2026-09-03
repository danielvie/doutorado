# Repecho, Biel, Olm, and Fossas Colet (2017)

Status: descriptive source summary
BibTeX key: `repecho2017switchingFrequency`
Source record: `latex/references.bib`; publication DOI: `10.1109/TPEL.2016.2546382`
Read when: comparing different ways of feeding back switching timing

## Bibliographic identity

V. Repecho, D. Biel, J. M. Olm, and E. Fossas Colet, “Switching Frequency Regulation in Sliding Mode Control by a Hysteresis Band Controller,” *IEEE Transactions on Power Electronics*, 32(2), 1557–1569, 2017.

## Problem

The paper addresses regulation of switching frequency in sliding-mode control, where the switching period varies with operating conditions and hysteresis behavior.

## System and setting

The controller operates through a hysteresis band in a power-electronics switching system. Measured switching-period behavior is used to regulate frequency.

## Approach

The paper updates the hysteresis-band amplitude with feedback, including integral action and tracking feedforward compensation. The timing quantity being regulated is the measured switching period rather than the interior switching instants of a prescribed multi-interval cycle.

## Main contribution

The source develops a switching-frequency regulation mechanism based on hysteresis-band feedback.

## Evidence

The paper reports analysis and switching-frequency regulation results for its sliding-mode power-electronics setting.

## Assumptions and limitations

The actuator is hysteresis-band adaptation. It does not define a fixed-period cycle with a prescribed mode order, independent interior switching-instant offsets, or a dwell-conditioning scalar.

## Concepts useful for later reading

- switching-frequency regulation;
- hysteresis-band control;
- measured switching-period error;
- integral feedback;
- tracking feedforward.

## Source pointers

The project reference review records the source sections and equations used to distinguish its actuator from the timing actuator in the manuscript.
