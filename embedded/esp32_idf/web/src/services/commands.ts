import { bleManager } from "./BleManager";
import { useBleStore } from "../store/bleStore";
import { useUiStore } from "../store/uiStore";
import { useSessionStore } from "../store/sessionStore";

// Single path for every command the UI sends (D4). Guards against firing
// while disconnected (which would otherwise trigger a surprise reconnect via
// sendBinary) and records the command into the active session (D2).
export const sendCommand = async (
    name: string,
    payload: Record<string, unknown> = {},
) => {
    const { isConnected, setCommandError } = useBleStore.getState();
    const { isMocking } = useUiStore.getState();

    if (!isConnected && !isMocking) {
        setCommandError(`[${name}] not sent: device is disconnected`);
        return null;
    }

    useSessionStore.getState().recordCommand(name, payload);

    if (!isConnected) return null; // mock mode: recorded, nothing to send

    return bleManager.sendCommand(name, payload);
};

// Connection-aware enablement for command-issuing controls.
export const useIsLive = () => {
    const isConnected = useBleStore((s) => s.isConnected);
    const isMocking = useUiStore((s) => s.isMocking);
    return isConnected || isMocking;
};
