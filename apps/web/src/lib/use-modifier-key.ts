'use client';

import { useSyncExternalStore } from 'react';

/**
 * Returns the platform's primary modifier key glyph: `⌘` on Mac, `Ctrl`
 * elsewhere.
 *
 * Implementation note: uses `useSyncExternalStore` so the platform check
 * happens synchronously after hydration without an extra `useEffect` tick.
 * The "subscribe" callback is a no-op because platform doesn't change at
 * runtime — this is purely a snapshot read.
 *
 * Server snapshot returns `false` (Ctrl) — that's the safer default since
 * non-Mac users globally outnumber Mac users. If the client is on Mac, the
 * snapshot flips to `true` after hydration; React reconciles in the same
 * commit, so no flicker.
 */
function detectIsMac(): boolean {
  if (typeof navigator === 'undefined') return false;
  const platform =
    // @ts-expect-error — userAgentData not yet in lib.dom
    (navigator.userAgentData?.platform as string | undefined) || navigator.platform || '';
  return /Mac|iPad|iPhone/i.test(platform);
}

const noopSubscribe = () => () => {};
const serverSnapshot = () => false;

export function useModifierKey(): { glyph: string; isMac: boolean } {
  const isMac = useSyncExternalStore(noopSubscribe, detectIsMac, serverSnapshot);
  return { glyph: isMac ? '⌘' : 'Ctrl', isMac };
}
