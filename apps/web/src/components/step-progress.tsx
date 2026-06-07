'use client';

import { usePathname } from 'next/navigation';
import { cn } from '@lexicon/design-system';
import { useJudgeCounsel } from '@/context/judge-counsel-context';

const SESSION_ROUTES = ['/', '/deliberation', '/opinion'];

const STEPS = [
  { path: '/', label: 'Input Perkara', short: '01' },
  { path: '/deliberation', label: 'Musyawarah', short: '02' },
  { path: '/opinion', label: 'Pendapat Hukum', short: '03' },
];

export function StepProgress() {
  const pathname = usePathname();
  const { sessionId, parsedCase } = useJudgeCounsel();

  if (!SESSION_ROUTES.includes(pathname)) return null;

  const foundIndex = STEPS.findIndex((s) => s.path === pathname);
  const currentIndex = foundIndex === -1 ? 0 : foundIndex;
  const current = STEPS[currentIndex] ?? STEPS[0]!;

  // Folio number — short, deterministic from the session id when present, or
  // a placeholder ledger style (so the user reads the strip as a docket entry,
  // not a metric). Keeps the visual weight even before the session is created.
  const folioNumber = sessionId ? `№ ${sessionId.slice(0, 6).toUpperCase()}` : '№ — — —';

  // Case type chip is shown only after parsing succeeds — quietly upgrades
  // the strip from "fresh dossier" to "open case".
  const caseTypeLabel = parsedCase?.case_type ? caseTypeToLabel(parsedCase.case_type) : null;

  return (
    <div
      className='anim-folio-rise mb-8 flex flex-col gap-3 border-b border-paper-edge pb-4 sm:flex-row sm:items-end sm:justify-between sm:gap-6'
      role='group'
      aria-label='Progres musyawarah'
    >
      <div className='min-w-0'>
        <div className='flex items-center gap-3 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
          {/* Re-keying on folioNumber forces a remount so the folio-flip
              animation runs whenever the placeholder dashes resolve to a
              real session ID. The eye reads "the dossier just got numbered." */}
          <span key={folioNumber} className='anim-folio-flip font-folio text-foreground/70'>
            {folioNumber}
          </span>
          {caseTypeLabel && (
            <>
              <span aria-hidden className='h-px w-4 bg-paper-edge' />
              <span key={caseTypeLabel} className='anim-folio-flip'>
                {caseTypeLabel}
              </span>
            </>
          )}
        </div>
        <h1 className='mt-1 font-rethink text-[1.625rem] font-semibold leading-tight tracking-tight text-foreground sm:text-[1.875rem]'>
          {current.label}
        </h1>
      </div>

      {/* Step dots — three quiet markers with a leading rule. The current step
          gets the primary fill (one teal per context, matching the brand rule). */}
      <ol className='flex items-center gap-3 text-[0.6875rem] uppercase tracking-[0.18em]'>
        {STEPS.map((step, idx) => {
          const isPast = idx < currentIndex;
          const isCurrent = idx === currentIndex;
          return (
            <li key={step.path} className='flex items-center gap-2'>
              <span
                aria-hidden
                className={cn(
                  'inline-flex size-1.5 rounded-full transition-flow',
                  isCurrent && 'bg-primary',
                  isPast && 'bg-foreground',
                  !isPast && !isCurrent && 'bg-paper-edge',
                )}
              />
              <span
                className={cn(
                  'font-folio',
                  isCurrent && 'text-foreground',
                  !isCurrent && 'text-muted-foreground/80',
                )}
              >
                <span className='hidden md:inline'>{step.short} · </span>
                {step.label}
              </span>
              {idx < STEPS.length - 1 && (
                <span aria-hidden className='ml-1 h-px w-4 bg-paper-edge' />
              )}
            </li>
          );
        })}
      </ol>
    </div>
  );
}

function caseTypeToLabel(type: string | null | undefined): string {
  switch (type) {
    case 'narcotics':
      return 'Perkara Narkotika';
    case 'corruption':
      return 'Perkara Korupsi';
    case 'general_criminal':
      return 'Perkara Pidana Umum';
    default:
      return 'Perkara';
  }
}
