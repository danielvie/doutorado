import { useState } from "react";

export function useStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    const stored = localStorage.getItem(key);
    if (!stored) return initialValue;

    try {
      return JSON.parse(stored) as T;
    } catch {
      return initialValue;
    }
  });

  const setStoredValue: typeof setValue = (nextValue) => {
    setValue((previousValue) => {
      const resolvedValue =
        nextValue instanceof Function ? nextValue(previousValue) : nextValue;
      localStorage.setItem(key, JSON.stringify(resolvedValue));
      return resolvedValue;
    });
  };

  return [value, setStoredValue] as const;
}
