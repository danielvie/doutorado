from importlib import import_module
from pathlib import Path

from prompt_toolkit import PromptSession
from prompt_toolkit.history import InMemoryHistory


matlab_engine = import_module("matlab.engine")
PROJECT_ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    print("Starting MATLAB R2025b...")
    engine = matlab_engine.start_matlab("-nodesktop -nosplash")
    engine.cd(str(PROJECT_ROOT), nargout=0)
    print(f"MATLAB working directory: {PROJECT_ROOT}")
    print("Type exit or quit to stop.")

    session = PromptSession(history=InMemoryHistory())

    try:
        while True:
            try:
                command = session.prompt("matlab> ").strip()
            except EOFError:
                print()
                break

            if command.rstrip(";").lower() in {"exit", "quit"}:
                break
            if not command:
                continue

            try:
                output = engine.evalc(command)
                if output:
                    print(output, end="" if output.endswith("\n") else "\n")
            except matlab_engine.MatlabExecutionError as error:
                print(error)
    except KeyboardInterrupt:
        print()
    finally:
        engine.quit()


if __name__ == "__main__":
    main()
