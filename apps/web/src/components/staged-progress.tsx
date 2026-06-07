'use client';

import { useEffect, useState } from 'react';
import { cn } from '@lexicon/design-system';

interface StagedProgressProps {
  phases: string[];
  /** Time in ms between phase advances. The final phase sticks until `running`
   *  flips false, so total duration is unbounded — the API resolution is
   *  what actually completes the work. */
  intervalMs?: number;
  running: boolean;
  variant?: 'inline' | 'stacked';
  /** Heading shown above the stacked variant. Ignored for inline. */
  title?: string;
  className?: string;
}

/**
 * StagedProgress — communicates "we are deliberately working through this"
 * for slow operations where the API doesn't expose real progress events.
 *
 * Two variants:
 * - `inline`: a single row (pulse dot + label). Drop into a button or label.
 * - `stacked`: a numbered task-list with done/active/pending dot states.
 *
 * The phase index advances on a timer, capped at `phases.length - 1` so the
 * last phase persists until `running` flips to false. This is the right
 * mental model — the user sees the work proceed; the final settle happens
 * when the actual response lands.
 *
 * All motion comes from globals.css (anim-thinking-pulse, anim-message-rise,
 * anim-caret-blink, anim-shimmer) and respects prefers-reduced-motion via
 * those classes' existing guards.
 */
export function StagedProgress(props: StagedProgressProps) {
  if (!props.running) return null;
  // Re-mount the inner component when `running` flips on so phase state
  // starts fresh — cleaner than imperatively resetting state inside an
  // effect, and the natural shape since the component returns null when not
  // running anyway.
  return <StagedProgressInner {...props} />;
}

function StagedProgressInner({
  phases,
  intervalMs = 4000,
  variant = 'stacked',
  title,
  className,
}: Omit<StagedProgressProps, 'running'>) {
  const [activeIndex, setActiveIndex] = useState(0);

  useEffect(() => {
    const id = window.setInterval(() => {
      setActiveIndex((i) => Math.min(i + 1, phases.length - 1));
    }, intervalMs);
    return () => window.clearInterval(id);
  }, [intervalMs, phases.length]);

  if (variant === 'inline') {
    const label = phases[activeIndex] ?? '';
    return (
      <span
        className={cn('inline-flex items-center gap-2', className)}
        role='status'
        aria-live='polite'
      >
        <span
          aria-hidden
          className='inline-block size-1.5 shrink-0 rounded-full bg-current anim-thinking-pulse'
        />
        {/* Re-keying on activeIndex remounts the label so message-rise plays
            on every transition. The previous phrase fades out implicitly via
            the new node taking its place. */}
        <span key={activeIndex} className='anim-message-rise'>
          {label}
        </span>
      </span>
    );
  }

  return (
    <div className={cn('flex flex-col gap-4', className)} role='status' aria-live='polite'>
      {title && (
        <p className='font-rethink text-base font-medium leading-tight text-foreground'>{title}</p>
      )}

      <ol className='space-y-3'>
        {phases.map((phase, i) => {
          const isDone = i < activeIndex;
          const isActive = i === activeIndex;
          return (
            <li key={phase} className='flex items-start gap-3'>
              <span
                aria-hidden
                className={cn(
                  'mt-1.5 inline-block size-1.5 shrink-0 rounded-full transition-flow',
                  isDone && 'bg-foreground',
                  isActive && 'bg-primary anim-thinking-pulse',
                  !isDone && !isActive && 'border border-paper-edge bg-transparent',
                )}
              />
              <span
                className={cn(
                  'text-[0.9375rem] leading-7 transition-flow',
                  isDone && 'text-muted-foreground/85',
                  isActive && 'text-foreground',
                  !isDone && !isActive && 'text-muted-foreground/50',
                )}
              >
                {phase}
                {isActive && <span aria-hidden className='anim-caret-blink ml-1' />}
              </span>
            </li>
          );
        })}
      </ol>

      {/* Hairline shimmer below the list — the same vocabulary as the
          deliberation streaming bar, recycled here to say "still working". */}
      <div className='relative mt-1 h-px overflow-hidden bg-paper-edge'>
        <span aria-hidden className='anim-shimmer absolute inset-0 block' />
      </div>
    </div>
  );
}
