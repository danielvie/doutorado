
export function _create_signal(alpha:number) {
    
    let E = 5
    // let C1 = 470e-6
    // let C2 = 470e-6
    // let L = 100*1e-3
    let R = 22
    
    let n = 3 // number of switch cells
    let T = 0.28*1e-3 // period of cycle
    
    let iMax = E/R
    let iLref = iMax*alpha // current setpoint
    
    console.log(`iMax: ${iMax}, iLref: ${iLref}`)
    
    let res = industrial_solution(alpha, n, T)
    
    const {Omega, dtSwitch} = res
    
    // set values in time and modes
    const dtSwitch_us = dtSwitch.map(v => v*1e6)
    
    return {
        time: dtSwitch_us.map(Math.round).join(", "),
        mode: Omega.map(it => (it-1)).join(", ")
    }
}

export function industrial_solution(alpha:number, nSwitches:number, T:number) {
    
    // Step 1: Define t0,i; ton,i; toff,i and initial state of the ith switch cell
    let t0 = Array(nSwitches).fill(0)
    let ton = Array(nSwitches).fill(0)
    let toff = Array(nSwitches).fill(0)
    let initialState:number[] = Array(nSwitches).fill(0)
    for (let i = 0; i < nSwitches; i++) {
        t0[i] = i*T/nSwitches
        toff[i] = (t0[i] + alpha*T/2) % T
        ton[i] = (t0[i] + T - alpha*T/2) % T
        
        // note that ton[i] is never equal to toff[i] with 0 < alpha < 1
        if (ton[i] < toff[i]) {
            initialState[i] = 0;
        } else {
            initialState[i] = 1;
        }
    }
    
    // Step 2: Obtain switching times
    let tSwitch_unsorted = [...ton, ...toff]
    const indexSort = Array.from(tSwitch_unsorted.keys())
    
    indexSort.sort((a, b) => tSwitch_unsorted[a] - tSwitch_unsorted[b]);
    let tSwitch = indexSort.map(i => tSwitch_unsorted[i])
    
    // Step 3: obtain mode sequence in binary coding form
    // note that the final state is equal to the initial state

    let OmegaBin: number[][] = []
    OmegaBin.push(initialState)
    
    let aux = [...Array(nSwitches).keys()]
    const SwitchUnsorted = [...aux, ...aux]
    const SwitchId = indexSort.map(i => SwitchUnsorted[i])

    for (let i = 0; i < (2*nSwitches)-1; i++) {
        let previousState = OmegaBin[i];
        let SwitchToChange = SwitchId[i];
        let newState = [...previousState];

        newState[SwitchToChange] = 1 - previousState[SwitchToChange]
        OmegaBin.push(newState);
    }
    
    // Step 4: Convert the mode sequence to decimal form
    const Omega = []

    const bin2dec = (bin:any) => {
        return bin.reverse().reduce((acc:any, value:any, idx:any) => acc + value*Math.pow(2, idx))
    }

    for (let i = 0; i < 2*nSwitches; i++) {
        Omega.push(1 + bin2dec(OmegaBin[i]))
    }
    
    // Step 5: Convert tSwitch to dtSwitch assuming that the final switching
    // time will be shifted to t = T
    
    let dtSwitch = [0, ...tSwitch].map((value, idx, arr) => value - arr[idx-1]).slice(1)
    dtSwitch[0] = dtSwitch[0] + T - tSwitch[tSwitch.length-1]

    const res = {
        "Omega": Omega,
        "dtSwitch": dtSwitch,
        "tSwitch": tSwitch
    }

    return res
}