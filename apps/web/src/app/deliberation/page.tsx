'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { CouncilDebate } from '@/components/council-debate';
import { useJudgeCounsel } from '@/context/judge-counsel-context';
import { UIDeliberationMessage } from '@/lib/mappers';
import { LegalOpinionDraft } from '@/types/api';

export default function DeliberationPage() {
  const router = useRouter();
  const { caseFacts, setMessages, setOpinion } = useJudgeCounsel();

  useEffect(() => {
    if (!caseFacts) {
      router.replace('/');
    }
  }, [caseFacts, router]);

  const handleDeliberationComplete = (
    finalMessages: UIDeliberationMessage[],
    finalOpinion: LegalOpinionDraft,
  ) => {
    setMessages(finalMessages);
    setOpinion(finalOpinion);
    router.push('/opinion');
  };

  if (!caseFacts) return null;

  return <CouncilDebate caseFacts={caseFacts} onComplete={handleDeliberationComplete} />;
}
