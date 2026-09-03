# Albea-Sanchez, Sferlazza, Gómez-Estern, and Gordillo (2021)

Status: descriptive source summary
BibTeX key: `albea2021hybridAffinePwm`
Source record: `latex/references.bib`; publication DOI: `10.1109/TCSI.2021.3083900`
Read when: studying hybrid-affine converter modeling with PWM inputs

## Bibliographic identity

C. Albea-Sanchez, A. Sferlazza, F. Gómez-Estern, and F. Gordillo, “Control of Power Converters With Hybrid Affine Models and Pulse-Width Modulated Inputs,” *IEEE Transactions on Circuits and Systems I: Regular Papers*, 68(8), 3485–3494, 2021.

## Problem

The paper studies control and stability analysis of power converters whose PWM and sample-and-hold behavior should be represented without reducing the dynamics to an averaged model.

## System and setting

The model is hybrid-affine and includes PWM and sample-and-hold variables. Converter evolution is represented through subinterval dynamics.

## Approach

The paper uses exact propagation over two subintervals and incorporates the switching and sampling variables into a hybrid-affine formulation. It provides a Lyapunov analysis for the resulting model.

## Main contribution

The source develops a hybrid-affine converter model with explicit PWM behavior and stability analysis.

## Evidence

The paper provides analytical results and converter examples for the proposed model and control analysis.

## Assumptions and limitations

Its model and control setting are not the same as the prescribed nine-interval cycle and switching-instant conditioner used in this project. The source does not establish the article's timing coordinates or scalar conditioning method.

## Concepts useful for later reading

- hybrid-affine converter models;
- PWM and sample-and-hold variables;
- exact subinterval propagation;
- Lyapunov analysis.

## Source pointers

The article introduces this source near the converter equations in Section 4. The project citation review records the equations and theorem used for that narrow modeling context.
