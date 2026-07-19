from importlib import import_module
from pathlib import Path

try:
    # Importing readline enables line editing and history for input().
    import readline

    readline.set_history_length(1_000)
except ImportError:
    pass


matlab_engine = import_module("matlab.engine")
PROJECT_ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    print("Starting MATLAB R2025b...")
    engine = matlab_engine.start_matlab("-nodesktop -nosplash")
    engine.cd(str(PROJECT_ROOT), nargout=0)
    print(f"MATLAB working directory: {PROJECT_ROOT}")
    print("Type exit or quit to stop.")

    try:
        while True:
            try:
                command = input("matlab> ").strip()
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
