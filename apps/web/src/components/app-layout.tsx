'use client';

import type React from 'react';
import { useEffect } from 'react';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { JudgeCounselProvider } from '@/context/judge-counsel-context';
import { Header } from '@/components/header';
import { StepProgress } from '@/components/step-progress';

export function AppLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
  }, [pathname]);

  return (
    <JudgeCounselProvider>
      <div className='min-h-screen bg-background text-foreground'>
        <Header />
        <main className='mx-auto max-w-6xl px-4 pb-24 pt-10 sm:px-8 sm:pt-14'>
          <StepProgress />
          {children}
        </main>
        <footer className='mx-auto flex max-w-6xl justify-center px-4 pb-10 sm:px-8'>
          <div
            className='inline-flex items-center gap-2 border-t border-paper-edge pt-4 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'
            aria-label='Powered by Lexicon'
          >
            <span>Powered by</span>
            <Image
              src='/images/img_logo_lexicon.webp'
              alt='Lexicon'
              width={96}
              height={25}
              className='h-5 w-auto opacity-85'
              priority={false}
            />
          </div>
        </footer>
      </div>
    </JudgeCounselProvider>
  );
}
