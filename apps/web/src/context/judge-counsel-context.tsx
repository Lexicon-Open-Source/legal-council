'use client';

import React, { createContext, useCallback, useContext, useState, ReactNode } from 'react';
import { UIDeliberationMessage } from '@/lib/mappers';
import {
  DeliberationPhase,
  LegalOpinionDraft,
  ParsedCaseInput,
  PhaseMetadata,
  SimilarCase,
} from '@/types/api';

interface JudgeCounselContextType {
  sessionId: string | null;
  setSessionId: (id: string | null) => void;
  caseFacts: string;
  setCaseFacts: (facts: string) => void;
  parsedCase: ParsedCaseInput | null;
  setParsedCase: (parsed: ParsedCaseInput | null) => void;
  similarCases: SimilarCase[];
  setSimilarCases: (cases: SimilarCase[]) => void;
  messages: UIDeliberationMessage[];
  setMessages: React.Dispatch<React.SetStateAction<UIDeliberationMessage[]>>;
  opinion: LegalOpinionDraft | null;
  setOpinion: (opinion: LegalOpinionDraft | null) => void;
  currentPhase: DeliberationPhase | null;
  setCurrentPhase: (phase: DeliberationPhase | null) => void;
  phaseMetadata: PhaseMetadata | null;
  setPhaseMetadata: (metadata: PhaseMetadata | null) => void;
  initialStreamPending: boolean;
  setInitialStreamPending: (pending: boolean) => void;
  reset: () => void;
}

const JudgeCounselContext = createContext<JudgeCounselContextType | undefined>(undefined);

export function JudgeCounselProvider({ children }: { children: ReactNode }) {
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [caseFacts, setCaseFacts] = useState('');
  const [parsedCase, setParsedCase] = useState<ParsedCaseInput | null>(null);
  const [similarCases, setSimilarCases] = useState<SimilarCase[]>([]);
  const [messages, setMessages] = useState<UIDeliberationMessage[]>([]);
  const [opinion, setOpinion] = useState<LegalOpinionDraft | null>(null);
  const [currentPhase, setCurrentPhase] = useState<DeliberationPhase | null>(null);
  const [phaseMetadata, setPhaseMetadata] = useState<PhaseMetadata | null>(null);
  const [initialStreamPending, setInitialStreamPending] = useState(false);

  const reset = useCallback(() => {
    setSessionId(null);
    setCaseFacts('');
    setParsedCase(null);
    setSimilarCases([]);
    setMessages([]);
    setOpinion(null);
    setCurrentPhase(null);
    setPhaseMetadata(null);
    setInitialStreamPending(false);
  }, []);

  return (
    <JudgeCounselContext.Provider
      value={{
        sessionId,
        setSessionId,
        caseFacts,
        setCaseFacts,
        parsedCase,
        setParsedCase,
        similarCases,
        setSimilarCases,
        messages,
        setMessages,
        opinion,
        setOpinion,
        currentPhase,
        setCurrentPhase,
        phaseMetadata,
        setPhaseMetadata,
        initialStreamPending,
        setInitialStreamPending,
        reset,
      }}
    >
      {children}
    </JudgeCounselContext.Provider>
  );
}

export function useJudgeCounsel() {
  const context = useContext(JudgeCounselContext);
  if (context === undefined) {
    throw new Error('useJudgeCounsel must be used within a JudgeCounselProvider');
  }
  return context;
}
