'use client';

import { useEffect } from 'react';
import { CaseInputForm } from '@/components/case-input-form';
import { useJudgeCounsel } from '@/context/judge-counsel-context';

export default function Home() {
  const { reset } = useJudgeCounsel();

  useEffect(() => {
    reset();
  }, [reset]);

  return <CaseInputForm />;
}
