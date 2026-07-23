# MATLAB Simulation Project Instructions

## Required context

Before investigating, editing, or running commands, read [`README.md`](README.md).
It defines the repository-relative paths, MATLAB package structure, supported
simulation configurations, and command entry points. Resolve paths from that
map rather than assuming a repository-root working directory.

## Project entry points

- Use [`Taskfile.yml`](Taskfile.yml) for normal run, test, clean, and MATLAB
  REPL commands. Start with `task --list` when choosing a task.
- Use [`t.m`](t.m) for interactive MATLAB commands: `t('run', name)`,
  `t('test')`, `t('demo', name)`, and `t('projection', name)`.
- Start runnable simulation, experiment, demo, and test flows through the
  `+Runner` package. Do not introduce or reference the retired `+z_run`
  package name.

## Structure

- Core model and control code belongs in the `+*` packages and `@Simulation`.
- Runnable entry points belong in `+Runner` subpackages.
- Project documentation belongs in [`DOCS/`](DOCS/); use the README's
  Repository Paths section to navigate to related thesis, embedded, and
  research-material projects.
