// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.
//
export const signalEdgeOverheadCommands = {
  up: "signal.set_edge_overhead_up",
  down: "signal.set_edge_overhead_down",
} as const;

export const createCyclesPayload = (cycles: number) => ({ cycles });

// Creates a switching signal based on a duty cycle
export function _create_signal(alpha: number) {
  // System parameters
  // let E = 5; // Input voltage (V)
  // let C1 = 470e-6      // Capacitor 1 value (F) - commented out, not used
  // let C2 = 470e-6      // Capacitor 2 value (F) - commented out, not used
  // let L = 100*1e-3     // Inductor value (H) - commented out, not used
  // let R = 22; // Resistance (Ohms)

  const n = 3; // Number of switch cells
  const T = 0.28 * 1e-3; // Period of switching cycle (seconds)

  // Calculate current parameters
  // let iMax = E / R; // Maximum current
  // let iLref = iMax * alpha; // Current setpoint based on duty cycle

  // console.log(`iMax: ${iMax}, iLref: ${iLref}`);

  // Calculate switching pattern using industrial solution algorithm
  const res = industrial_solution(alpha, n, T);

  const { Omega, dtSwitch } = res;

  // Convert times to 0.1 us ticks for the ESP32 signal payload.
  const dtSwitch_tenths_us = dtSwitch.map((v) => v * 1e7);

  // Return formatted strings for time and mode values
  // Return formatted strings for time and mode values
  const binaryModes = Omega.map((val) =>
    (val - 1).toString(2).padStart(3, "0"),
  );

  return {
    time: dtSwitch_tenths_us.map(Math.round).join(", "),
    mode: Omega.map((it) => it - 1).join(", "),
    binary: {
      s1: binaryModes.map((b) => b[2]).join(""), // Switch 1 (LSB)
      s2: binaryModes.map((b) => b[1]).join(""), // Switch 2
      s3: binaryModes.map((b) => b[0]).join(""), // Switch 3 (MSB)
    },
  };
}

// Calculates optimal switching patterns for a multi-cell converter
export function industrial_solution(
  alpha: number,
  nSwitches: number,
  T: number,
) {
  // Step 1: Define t0,i; ton,i; toff,i and initial state of the ith switch cell
  // t0 = initial time for each switch
  // ton = turn-on time for each switch
  // toff = turn-off time for each switch
  const t0 = Array(nSwitches).fill(0);
  const ton = Array(nSwitches).fill(0);
  const toff = Array(nSwitches).fill(0);
  const initialState: number[] = Array(nSwitches).fill(0);

  for (let i = 0; i < nSwitches; i++) {
    // Initial time is evenly distributed across the period
    t0[i] = (i * T) / nSwitches;

    // Calculate turn-off and turn-on times based on duty cycle
    toff[i] = (t0[i] + (alpha * T) / 2) % T;
    ton[i] = (t0[i] + T - (alpha * T) / 2) % T;

    // Determine initial state based on relative positions of ton and toff
    // note that ton[i] is never equal to toff[i] with 0 < alpha < 1
    if (ton[i] < toff[i]) {
      initialState[i] = 0; // Initially OFF
    } else {
      initialState[i] = 1; // Initially ON
    }
  }

  // Step 2: Obtain switching times in chronological order
  // Combine all turn-on and turn-off times into a single array
  const tSwitch_unsorted = [...ton, ...toff];

  // Create array of indices to track original positions after sorting
  const indexSort = Array.from(tSwitch_unsorted.keys());

  // Sort the indices based on their corresponding time values
  indexSort.sort((a, b) => tSwitch_unsorted[a] - tSwitch_unsorted[b]);

  // Get the sorted switching times
  const tSwitch = indexSort.map((i) => tSwitch_unsorted[i]);

  // Step 3: Obtain mode sequence in binary coding form
  // The sequence of switch states through one complete cycle
  // Note that the final state is equal to the initial state
  const OmegaBin: number[][] = [];
  OmegaBin.push(initialState); // Start with the initial state

  // Create an array to map sorted indices back to switch IDs
  const aux = [...Array(nSwitches).keys()]; // [0, 1, 2, ..., nSwitches-1]
  const SwitchUnsorted = [...aux, ...aux]; // Duplicate for both on and off events
  const SwitchId = indexSort.map((i) => SwitchUnsorted[i]); // Map to original switch IDs

  // Generate the sequence of switch states after each switching event
  for (let i = 0; i < 2 * nSwitches - 1; i++) {
    const previousState = OmegaBin[i]; // Get the previous state
    const SwitchToChange = SwitchId[i]; // Which switch is changing
    const newState = [...previousState]; // Copy the previous state

    // Toggle the state of the switch (0→1 or 1→0)
    newState[SwitchToChange] = 1 - previousState[SwitchToChange];
    OmegaBin.push(newState); // Add the new state to the sequence
  }

  // Step 4: Convert the binary mode sequence to decimal form for easier processing
  const Omega: number[] = [];

  // Helper function to convert binary array to decimal number
  // Each bit position represents a switch (LSB = switch 0, etc.)
  const bin2dec = (bin: number[]) => {
    return bin
      .slice()
      .reverse()
      .reduce((acc, value, idx) => acc + value * Math.pow(2, idx), 0);
  };

  // Convert each binary state to its decimal representation (+1 for 1-based indexing)
  for (let i = 0; i < 2 * nSwitches; i++) {
    Omega.push(1 + bin2dec(OmegaBin[i]));
  }

  // Step 5: Calculate time intervals between switching events (dtSwitch)
  // Instead of absolute times, we want the durations between switches

  // Calculate differences between consecutive switching times
  const dtSwitch = [0, ...tSwitch]
    .map((value, idx, arr) => value - arr[idx - 1])
    .slice(1);

  // Special case for first interval: need to wrap around from last switch to period T
  dtSwitch[0] = dtSwitch[0] + T - tSwitch[tSwitch.length - 1];

  // Return the results: switching modes and time intervals
  const res = {
    Omega: Omega, // Array of switching modes (decimal representation)
    dtSwitch: dtSwitch, // Array of time intervals between switching events
    tSwitch: tSwitch, // Array of absolute switching times
  };

  return res;
}
