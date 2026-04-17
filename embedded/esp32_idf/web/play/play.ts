const bin2dec = (bin: number[]): number => {
    return [...bin].reverse().reduce((acc: number, value: number, idx: number) =>
        acc + value * Math.pow(2, idx)
    );
};

export function industrial_solution(alpha: number, nSwitches: number, T: number) {
    // Step 1: Define t0,i; ton,i; toff,i and initial state of the ith switch cell
    // t0 = initial time for each switch
    // ton = turn-on time for each switch
    // toff = turn-off time for each switch
    let t0 = Array(nSwitches).fill(0);
    let ton = Array(nSwitches).fill(0);
    let toff = Array(nSwitches).fill(0);
    let initialState: number[] = Array(nSwitches).fill(0);

    for (let i = 0; i < nSwitches; i++) {
        // Initial time is evenly distributed across the period
        t0[i] = i * T / nSwitches;

        // Calculate turn-off and turn-on times based on duty cycle
        toff[i] = (t0[i] + alpha * T / 2) % T;
        ton[i] = (t0[i] + T - alpha * T / 2) % T;

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
    let tSwitch_unsorted = [...ton, ...toff];

    // Create array of indices to track original positions after sorting
    const indexSort = Array.from(tSwitch_unsorted.keys());

    // Sort the indices based on their corresponding time values
    indexSort.sort((a, b) => tSwitch_unsorted[a] - tSwitch_unsorted[b]);

    // Get the sorted switching times
    let tSwitch = indexSort.map((i) => tSwitch_unsorted[i]);

    // Step 3: Obtain mode sequence in binary coding form
    // The sequence of switch states through one complete cycle
    // Note that the final state is equal to the initial state
    let OmegaBin: number[][] = [];
    OmegaBin.push(initialState); // Start with the initial state

    // Create an array to map sorted indices back to switch IDs
    let aux = [...Array(nSwitches).keys()]; // [0, 1, 2, ..., nSwitches-1]
    const SwitchUnsorted = [...aux, ...aux]; // Duplicate for both on and off events
    const SwitchId = indexSort.map((i) => SwitchUnsorted[i]); // Map to original switch IDs

    // Generate the sequence of switch states after each switching event
    for (let i = 0; i < (2 * nSwitches) - 1; i++) {
        let previousState = OmegaBin[i]; // Get the previous state
        let SwitchToChange = SwitchId[i]; // Which switch is changing
        let newState = [...previousState]; // Copy the previous state

        // Toggle the state of the switch (0→1 or 1→0)
        newState[SwitchToChange] = 1 - previousState[SwitchToChange];
        OmegaBin.push(newState); // Add the new state to the sequence
    }

    // Step 4: Convert the binary mode sequence to decimal form for easier processing
    const Omega: number[] = [];

    // Convert each binary state to its decimal representation (+1 for 1-based indexing)
    for (let i = 0; i < 2 * nSwitches; i++) {
        Omega.push(1 + bin2dec(OmegaBin[i]));
    }

    // Step 5: Calculate time intervals between switching events (dtSwitch)
    // Instead of absolute times, we want the durations between switches

    // Calculate differences between consecutive switching times
    let dtSwitch = [0, ...tSwitch].map((value, idx, arr) =>
        value - arr[idx - 1]
    ).slice(1);

    // Special case for first interval: need to wrap around from last switch to period T
    dtSwitch[0] = dtSwitch[0] + T - tSwitch[tSwitch.length - 1];

    // Return the results: switching modes and time intervals
    const res = {
        "Omega": Omega, // Array of switching modes (decimal representation)
        "dtSwitch": dtSwitch, // Array of time intervals between switching events
        "tSwitch": tSwitch, // Array of absolute switching times
    };

    return res;
}

function compute_phase_shift(alpha: number, phase_n: number, T: number) {
    
    // Step 1: define time intervals
    const time_pair: number[][] = []
    let omega_bin: number[][] = []

    for (let i = 0; i < phase_n; i++) {
        // Initial time is evenly distributed across the period
        const t0 = i * T / phase_n;

        // Calculate turn-off and turn-on times based on duty cycle
        const toff = (t0 + alpha * T / 2) % T;
        const ton  = (t0 + T - alpha * T / 2) % T;
        
        // Add time in pair with the index of the signal
        time_pair.push([ton, i])
        time_pair.push([toff, i])

        // Determine initial state based on relative positions of ton and toff
        // note that ton[i] is never equal to toff[i] with 0 < alpha < 1
        if (ton < toff) {
            omega_bin.push([0])
        } else {
            omega_bin.push([1])
        }
    }

    time_pair.sort((a, b) => a[0] - b[0]) // sort by time

    // Step 2: Compute signals
    for (let i = 0; i < time_pair.length-1; i++) {
        const [_, idx] = time_pair[i]

        // copy last elements
        const si_len = omega_bin[0].length
        omega_bin.forEach((el, i) => {
            omega_bin[i].push(el[si_len-1])
        })
        
        // update element switch
        omega_bin[idx][si_len] = 1 - omega_bin[idx][si_len]
    }

   
    // Step 3: Compute Omega Decimal
    const omega: number[] = []
    for (let i = 0; i < omega_bin[0].length; i++) {
        const bin: number[] = []

        for (let j = 0; j < omega_bin.length; j++) {
            bin.push(omega_bin[j][i])
        }

        omega.push(1 + bin2dec(bin))
    }
    
    // Step 4: Compute dt_values
    const time_values = time_pair.map(el => el[0])
    
    // Calculate differences between consecutive switching times
    let time_dt_values = [0, ...time_values].map((value, idx, arr) =>
        value - arr[idx - 1]
    ).slice(1);

    // Special case for first interval: need to wrap around from last switch to period T
    time_dt_values[0] = time_dt_values[0] + T - time_values[time_values.length - 1];

    const res = {
        "Omega": omega,
        "dtSwitch": time_dt_values,
        "tSwitch": time_values,
    }
    
    return res
}


const n = 3; // Number of switch cells
// const T = 0.28 * 1e-3; // Period of switching cycle (seconds)
const T = 280; // Period of switching cycle (seconds)
const alpha = 0.1;

const res = industrial_solution(alpha, n, T);
const res_2 = compute_phase_shift(alpha, n, T);
console.log(res)
console.log(res_2)

const dec2bin = (num: number, len: number) => {
    return num.toString(2).padStart(len, '0');
}

const s1:string[] = []
const s2:string[] = []
const s3:string[] = []

for (const el of res.Omega) {
    const b =dec2bin(el-1, 3) 
    // console.log(b)
    s1.push(b[0])
    s2.push(b[1])
    s3.push(b[2])
}

// let msg = "        t1    t2    t3 t4 t5 t6\n";
// msg += '     '

const space = '    '
let msg_title = space
let msg_time = space
let msg_s1 = 's1: '
let msg_s2 = 's2: '
let msg_s3 = 's3: '

res.tSwitch.forEach((el: number, i: number) => {
    const el_str = el.toFixed(2)
    const el_len = el_str.length
    
    const space_i = ' '.repeat(el_len-1)
    
    msg_title += `${space_i} t${i+1}`
    msg_time  += `  ${el_str}`
    msg_s1    += `${space_i}  ${s1[i]}`
    msg_s2    += `${space_i}  ${s2[i]}`
    msg_s3    += `${space_i}  ${s3[i]}`
})

const line = '-'.repeat(msg_time.length)
const msg = `${msg_title}\n${line}\n${msg_time}\n${line}\n${msg_s1}\n${msg_s2}\n${msg_s3}\n`
console.log(msg)
