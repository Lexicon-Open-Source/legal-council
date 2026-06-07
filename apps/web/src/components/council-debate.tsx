'use client';

import type React from 'react';
import { useState, useRef, useEffect, useEffectEvent } from 'react';
import { Alert, AlertDescription, Button, Textarea } from '@lexicon/design-system';
import { AgentAvatar } from './agent-avatar';
import { Send, AlertCircle, Gavel } from 'lucide-react';
import { MessageBubble } from './message-bubble';
import { StagedProgress } from './staged-progress';
import { useDeliberation } from '@/hooks/useDeliberation';
import { useJudgeCounsel } from '@/context/judge-counsel-context';
import { apiService } from '@/services/api';
import { UIDeliberationMessage } from '@/lib/mappers';
import { LegalOpinionDraft, AgentId } from '@/types/api';
import { formatTargetedAgentMessage, getApiTargetAgent } from '@/lib/targeted-agent-message';

interface CouncilDebateProps {
  caseFacts: string;
  onComplete: (messages: UIDeliberationMessage[], opinion: LegalOpinionDraft) => void;
}

const AGENTS = {
  strict: {
    name: 'Legalis',
    role: 'Penafsir Ketat',
    blurb: 'Pembacaan undang-undang yang ketat dan letterlijk',
    id: 'strict' as AgentId,
  },
  humanist: {
    name: 'Humanis',
    role: 'Pendekatan Rehabilitatif',
    blurb: 'Mempertimbangkan rehabilitasi dan keadaan terdakwa',
    id: 'humanist' as AgentId,
  },
  historian: {
    name: 'Sejarawan',
    role: 'Ahli Yurisprudensi',
    blurb: 'Memetakan preseden dan putusan sebelumnya',
    id: 'historian' as AgentId,
  },
  user: { name: 'Anda', role: 'Hakim Ketua', blurb: '', id: 'user' as const },
  system: { name: 'Sistem', role: 'Sistem', blurb: '', id: 'system' as const },
};

const QUICK_ACTIONS = [
  {
    label: 'Tanya Legalis',
    hint: 'Minta pembacaan undang-undang yang ketat.',
    prompt: 'Legalis, apa pendapat Anda tentang perkara ini?',
    targetAgent: 'strict' as AgentId,
  },
  {
    label: 'Tanya Humanis',
    hint: 'Minta pertimbangan rehabilitasi dan keadaan terdakwa.',
    prompt: 'Humanis, dari sudut pandang rehabilitasi, bagaimana pandangan Anda?',
    targetAgent: 'humanist' as AgentId,
  },
  {
    label: 'Tanya Sejarawan',
    hint: 'Minta preseden dan yurisprudensi pembanding.',
    prompt: 'Sejarawan, apakah ada yurisprudensi yang relevan untuk perkara ini?',
    targetAgent: 'historian' as AgentId,
  },
];

export function CouncilDebate({ caseFacts, onComplete }: CouncilDebateProps) {
  const { sessionId, messages, setMessages, initialStreamPending, setInitialStreamPending } =
    useJudgeCounsel();

  const {
    streamInitialOpinions,
    sendMessageStreaming,
    continueDiscussionStreaming,
    loading: isSending,
    streaming: isStreaming,
    streamingAgentId,
    pacing: isPacing,
    pacingAgentId,
    loadMessages,
    error,
  } = useDeliberation(sessionId || '', messages, setMessages);

  const onLoadMessages = useEffectEvent(() => {
    if (sessionId && messages.length === 0) loadMessages();
  });
  useEffect(() => {
    onLoadMessages();
  }, [sessionId]);

  const onStreamInitialOpinions = useEffectEvent(async () => {
    if (!sessionId || !initialStreamPending || messages.length === 0) return;

    setInitialStreamPending(false);
    try {
      await streamInitialOpinions();
    } catch (e) {
      console.error('Failed to stream initial opinions:', e);
    }
  });
  useEffect(() => {
    void onStreamInitialOpinions();
  }, [sessionId, initialStreamPending]);

  const [userInput, setUserInput] = useState('');
  const [isGeneratingOpinion, setIsGeneratingOpinion] = useState(false);
  const [opinionError, setOpinionError] = useState<string | null>(null);
  const [isContinuing, setIsContinuing] = useState(false);

  const isAgentTyping = isSending || isStreaming || isContinuing || isPacing;
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const typingAgentId = streamingAgentId ?? pacingAgentId ?? null;
  const typingAgentName = typingAgentId ? AGENTS[typingAgentId]?.name : null;

  let lastAgentSpoken: AgentId | undefined;
  for (let index = messages.length - 1; index >= 0; index -= 1) {
    const sender = messages[index]?.sender;

    if (sender !== 'user' && sender !== 'system') {
      lastAgentSpoken = sender as AgentId;
      break;
    }
  }

  const getTargetAgent = (userMessage: string): AgentId | undefined => {
    const msg = userMessage.toLowerCase();
    if (msg.includes('legalis') || msg.includes('strict')) return 'strict';
    if (msg.includes('humanis') || msg.includes('rehabilit')) return 'humanist';
    if (msg.includes('sejarawan') || msg.includes('historian') || msg.includes('precedent'))
      return 'historian';
    return undefined;
  };

  const handleUserSubmit = async (text?: string, explicitTargetAgent?: AgentId) => {
    const messageText = text || userInput.trim();
    if (!messageText || isAgentTyping || !sessionId) return;

    setUserInput('');
    const targetAgent = explicitTargetAgent || getTargetAgent(messageText);
    const outboundMessage = formatTargetedAgentMessage(messageText, targetAgent);
    try {
      await sendMessageStreaming({
        content: outboundMessage,
        target_agent: getApiTargetAgent(targetAgent),
      });
    } catch (e) {
      console.error('Failed to send message:', e);
    }
    inputRef.current?.focus();
  };

  const handleContinueDiscussion = async () => {
    if (!sessionId || isAgentTyping) return;
    setIsContinuing(true);
    try {
      await continueDiscussionStreaming(1);
    } catch (e) {
      console.error('Failed to continue discussion:', e);
    } finally {
      setIsContinuing(false);
    }
  };

  const handleGenerateOpinion = async () => {
    if (!sessionId) return;
    setIsGeneratingOpinion(true);
    setOpinionError(null);
    try {
      const response = await apiService.generateOpinion(sessionId);
      onComplete(messages, response.opinion);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Gagal membuat pendapat hukum';
      setOpinionError(errorMessage);
      console.error('Failed to generate opinion:', error);
    } finally {
      setIsGeneratingOpinion(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleUserSubmit();
    }
  };

  const enoughForOpinion = messages.length >= 3;
  const messagesToOpinion = Math.max(0, 3 - messages.length);

  return (
    <div className='grid gap-8 lg:grid-cols-[18rem_minmax(0,1fr)]'>
      {/* COUNCIL — the round-table sidebar
          Sticky on desktop so the user always sees who's at the table
          and which judge is speaking right now. */}
      <aside className='anim-folio-rise-delay-1 lg:sticky lg:top-28 lg:self-start'>
        <div className='border-b border-paper-edge pb-4'>
          <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            Perkara
          </p>
          <p className='mt-2 line-clamp-4 text-[0.8125rem] leading-relaxed text-foreground/85'>
            {caseFacts}
          </p>
        </div>

        <p className='mt-6 text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
          Ruang musyawarah
        </p>
        <ul className='mt-3 space-y-3'>
          {(['strict', 'humanist', 'historian'] as const).map((agent) => {
            const a = AGENTS[agent];
            const isThinking = isAgentTyping && typingAgentId === agent;
            const isLast = !isAgentTyping && lastAgentSpoken === agent;
            return (
              <li key={agent} className='flex gap-3'>
                <AgentAvatar agent={agent} size='md' variant='marker' thinking={isThinking} />
                <div className='min-w-0 flex-1 pt-0.5'>
                  <div className='flex items-baseline gap-2'>
                    <span className='font-rethink text-sm font-medium text-foreground'>
                      {a.name}
                    </span>
                    <span className='text-[0.6875rem] uppercase tracking-[0.14em] text-muted-foreground/80'>
                      {a.role}
                    </span>
                  </div>
                  <p className='mt-0.5 line-clamp-2 text-xs leading-relaxed text-muted-foreground'>
                    {isThinking ? (
                      <span className='text-foreground anim-caret-blink'>menulis tanggapan</span>
                    ) : isLast ? (
                      <span className='text-foreground/75'>baru saja berbicara</span>
                    ) : (
                      a.blurb
                    )}
                  </p>
                </div>
              </li>
            );
          })}
        </ul>

        <div className='mt-6 border-t border-paper-edge pt-4'>
          <div className='flex items-center gap-2'>
            <AgentAvatar agent='user' size='sm' variant='dot' />
            <span className='font-rethink text-sm font-medium text-foreground'>Anda</span>
            <span className='text-[0.6875rem] uppercase tracking-[0.14em] text-muted-foreground/80'>
              Hakim Ketua
            </span>
          </div>
          <p className='mt-1 max-w-[26ch] text-xs leading-relaxed text-muted-foreground'>
            Anda memimpin sidang. Arahkan pertanyaan kepada hakim, atau biarkan mereka berdiskusi.
          </p>
        </div>
      </aside>

      {/* TRANSCRIPT + INPUT */}
      <section className='anim-folio-rise-delay-2 flex min-h-0 flex-col'>
        {/* Transcript — no chat-bubble framing, no card. The transcript IS
            the page; vertical rhythm carries hierarchy. */}
        <div className='flex-1 min-h-[420px] space-y-7 pb-8'>
          {messages.map((message) => (
            <MessageBubble key={message.id} message={message} />
          ))}

          {isSending && !isStreaming && (
            <div className='flex items-center gap-3 pl-6 text-sm text-muted-foreground'>
              <span className='inline-block size-1.5 rounded-full bg-foreground anim-thinking-pulse' />
              <span>
                {isContinuing
                  ? 'Hakim sedang bermusyawarah'
                  : typingAgentName
                    ? `${typingAgentName} sedang merumuskan tanggapan`
                    : 'Dewan sedang merespons'}
                <span className='anim-caret-blink' aria-hidden />
              </span>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Streaming hairline — appears only while a judge is writing.
            Sits flush with the transcript and is the single moving thing
            in the chamber while the user waits. */}
        <div className='relative h-px overflow-hidden bg-paper-edge'>
          {isAgentTyping && <span className='anim-shimmer absolute inset-0 block' />}
        </div>

        {error && (
          <Alert variant='destructive' className='mt-4'>
            <AlertCircle />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {/* INPUT PANEL — the chair's podium */}
        <div className='mt-4 rounded-md border border-paper-edge bg-paper transition-flow focus-within:border-foreground/30 focus-within:shadow-sm'>
          <div className='flex items-center justify-between gap-3 border-b border-paper-edge/70 px-4 py-2 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
            <span className='font-folio'>Pertanyaan Hakim Ketua</span>
            <span className='font-folio tabular-nums'>{messages.length} pesan</span>
          </div>

          <div className='border-b border-paper-edge/70 px-3 py-2'>
            <div className='flex flex-wrap items-center gap-2'>
              <span className='mr-1 text-[0.6875rem] uppercase tracking-[0.14em] text-muted-foreground'>
                Arahkan cepat
              </span>
              {QUICK_ACTIONS.map((action) => {
                return (
                  <button
                    key={action.label}
                    type='button'
                    title={action.hint}
                    onClick={() => handleUserSubmit(action.prompt, action.targetAgent)}
                    disabled={isAgentTyping}
                    className='press group inline-flex items-center gap-1.5 rounded-full border border-paper-edge bg-background px-2.5 py-1 text-xs text-foreground/80 transition-snap hover:border-foreground/30 hover:text-foreground disabled:cursor-not-allowed disabled:opacity-50'
                  >
                    <AgentAvatar agent={action.targetAgent} size='sm' variant='dot' />
                    {action.label}
                  </button>
                );
              })}
              <button
                type='button'
                onClick={handleContinueDiscussion}
                disabled={isAgentTyping || messages.length < 1}
                className='press inline-flex items-center gap-1.5 rounded-full border border-paper-edge bg-background px-2.5 py-1 text-xs text-foreground/80 transition-snap hover:border-foreground/30 hover:text-foreground disabled:cursor-not-allowed disabled:opacity-50'
              >
                <span aria-hidden className='inline-block size-1 rounded-full bg-foreground/40' />
                Biarkan hakim berdiskusi
              </button>
            </div>
          </div>

          <Textarea
            ref={inputRef}
            value={userInput}
            onChange={(e) => setUserInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder='Arahkan pertanyaan, minta klarifikasi, atau berikan pertimbangan Anda…'
            className='min-h-[80px] resize-none border-0 bg-transparent p-4 text-[0.9375rem] leading-7 text-foreground shadow-none placeholder:text-muted-foreground/70 focus-visible:ring-0'
            disabled={isAgentTyping}
          />
          <div className='flex flex-col gap-2 border-t border-paper-edge/70 px-3 py-2 sm:flex-row sm:items-center sm:justify-between'>
            <p className='text-xs text-muted-foreground'>
              Enter untuk kirim
              <span aria-hidden className='mx-1 text-muted-foreground/60'>
                ·
              </span>
              Shift+Enter untuk baris baru
            </p>
            <Button
              type='button'
              onClick={() => handleUserSubmit()}
              disabled={!userInput.trim() || isAgentTyping}
              className='press h-8 px-3 text-sm sm:ml-auto'
            >
              <Send className='size-3.5' />
              Kirim
            </Button>
          </div>
        </div>

        {/* OPINION CTA — replaced by a 3-phase drafting stage while
            isGeneratingOpinion is true. The stage takes the same vertical
            band so the page doesn't reflow, and the "Mengumpulkan argumen…
            Memetakan dasar hukum… Menyusun draf" walkthrough makes a 10-20s
            wait feel deliberate. */}
        {isGeneratingOpinion ? (
          <div className='anim-folio-rise mt-6 border-t border-paper-edge pt-6'>
            <StagedProgress
              variant='stacked'
              running={isGeneratingOpinion}
              intervalMs={5000}
              title='Pendapat hukum sedang dirumuskan'
              phases={[
                'Mengumpulkan argumen Legalis · Humanis · Sejarawan',
                'Memetakan dasar hukum dan yurisprudensi',
                'Menyusun draf pendapat',
              ]}
            />
          </div>
        ) : (
          <div className='mt-6 flex flex-col-reverse items-start gap-4 border-t border-paper-edge pt-6 sm:flex-row sm:items-center sm:justify-between'>
            <div className='text-xs text-muted-foreground'>
              {enoughForOpinion ? (
                <>Sudah cukup untuk merumuskan pendapat hukum dari musyawarah ini.</>
              ) : (
                <>
                  Tambah {messagesToOpinion} pesan lagi untuk membuka draf pendapat hukum
                  <span aria-hidden className='mx-1 text-muted-foreground/60'>
                    ·
                  </span>
                  <span className='font-folio tabular-nums text-foreground/70'>
                    {messages.length}/3
                  </span>
                </>
              )}
            </div>
            <Button
              onClick={handleGenerateOpinion}
              disabled={!enoughForOpinion || isAgentTyping}
              className='press h-10 px-4 text-sm'
            >
              <Gavel className='size-4' />
              Buat Pendapat Hukum
            </Button>
          </div>
        )}

        {opinionError && (
          <Alert variant='destructive' className='mt-4'>
            <AlertCircle />
            <AlertDescription>{opinionError}</AlertDescription>
          </Alert>
        )}
      </section>
    </div>
  );
}
