# Bluetooth Device Commands

## Fixed Commands
These commands do not require parameters and trigger specific actions on the device.

| Command   | Description                        |
|-----------|------------------------------------|
| `START`   | Initiates the signal.              |
| `HIGH`    | Sets all digital ports to HIGH.    |
| `STOP`    | Sets all digital ports to LOW.     |
| `LOW`     | Alias for `STOP`.                  |

## Parameterized Commands
These commands require parameters to configure device behavior. The format for each command is shown below, with examples provided after the table.

| Command       | Format                                    | Description                                          |
|---------------|-------------------------------------------|------------------------------------------------------|
| `CYCLE_NRUN`  | `CYCLE_NRUN:${value}`                     | Sets the `cycle_nrun` to the specified value.         |
| `SIGNAL`      | `SIGNAL:${time};${modes}`                 | Configures signal with time and mode values.          |

### Parameterized Command Examples
- **CYCLE_NRUN Example**: 
```powershell
CYCLE_NRUN:100
```
  - Sets `cycle_nrun` to the value `100`.

- **SIGNAL Example**: 
```powershell
SIGNAL:47,47,47,47,47,47;4,6,2,3,1,5
```
  - Sets `time` to the array `[47,47,47,47,47,47]` 
  - and `mode` to the array `[4,6,2,3,1,5]`.