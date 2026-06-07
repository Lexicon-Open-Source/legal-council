'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@lexicon/design-system';
import { useJudgeCounsel } from '@/context/judge-counsel-context';

const navItems = [
  { href: '/', label: 'Sesi Baru' },
  { href: '/cases', label: 'Kasus' },
  { href: '/sessions', label: 'Riwayat' },
];

export function Header() {
  const pathname = usePathname();
  const { sessionId, opinion } = useJudgeCounsel();
  const showActiveSessionLink = !!sessionId && (pathname === '/cases' || pathname === '/sessions');
  const activeSessionHref = opinion ? '/opinion' : '/deliberation';
  const folioNumber = sessionId ? `№ ${sessionId.slice(0, 6).toUpperCase()}` : null;

  return (
    <header className='sticky top-0 z-30 border-b border-border bg-background/85 backdrop-blur'>
      <div className='mx-auto flex max-w-6xl items-center justify-between gap-6 px-4 py-4 sm:px-8'>
        {/* Brand mark — a single tightly-spaced logotype, no decorative icon block.
            The tiny rotated rule below the wordmark gives a quiet "stamp" feel
            without resorting to badges or borders. */}
        <Link href='/' className='group flex min-w-0 items-baseline gap-3'>
          <span className='font-rethink text-[1.0625rem] font-semibold tracking-tight text-foreground'>
            Dewan Hakim
          </span>
          <span
            aria-hidden
            className='hidden h-px w-8 translate-y-[-4px] bg-foreground/25 transition-snap group-hover:w-12 group-hover:bg-primary sm:inline-block'
          />
          <span className='hidden text-[0.6875rem] uppercase tracking-[0.18em] text-muted-foreground sm:inline'>
            Ruang Musyawarah Virtual
          </span>
        </Link>

        <div className='flex items-center gap-3'>
          {showActiveSessionLink && (
            <Link
              href={activeSessionHref}
              className='hidden items-baseline gap-2 border-l border-paper-edge pl-4 text-xs text-muted-foreground transition-snap hover:text-foreground md:inline-flex'
            >
              <span className='font-folio text-foreground/75'>{folioNumber}</span>
              <span>{opinion ? 'lihat pendapat' : 'kembali ke musyawarah'}</span>
            </Link>
          )}

          <nav className='flex items-center gap-1' aria-label='Primary'>
            {navItems.map((item) => {
              const isActive =
                item.href === '/' ? pathname === '/' : pathname.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  aria-current={isActive ? 'page' : undefined}
                  className={cn(
                    'group relative rounded-sm px-3 py-1.5 text-sm transition-snap',
                    'text-muted-foreground hover:text-foreground',
                    isActive && 'text-foreground',
                  )}
                >
                  {item.label}
                  {/* underline rules out as the active indicator — it animates
                    in on hover so the nav feels alive without buttons. */}
                  <span
                    aria-hidden
                    className={cn(
                      'pointer-events-none absolute inset-x-2 -bottom-px h-px origin-center scale-x-0 bg-foreground transition-flow',
                      isActive ? 'scale-x-100 bg-primary' : 'group-hover:scale-x-100',
                    )}
                  />
                </Link>
              );
            })}
          </nav>
        </div>
      </div>
    </header>
  );
}
