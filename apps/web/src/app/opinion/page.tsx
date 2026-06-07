'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LegalOpinion } from '@/components/legal-opinion';
import { useJudgeCounsel } from '@/context/judge-counsel-context';

export default function OpinionPage() {
  const router = useRouter();
  const { opinion, messages, sessionId, parsedCase, reset } = useJudgeCounsel();

  useEffect(() => {
    if (!opinion) {
      router.replace('/');
    }
  }, [opinion, router]);

  const handleReset = () => {
    reset();
    router.push('/');
  };

  if (!opinion) return null;

  return (
    <LegalOpinion
      opinion={opinion}
      messages={messages}
      sessionId={sessionId}
      parsedCase={parsedCase}
      onReset={handleReset}
    />
  );
}
