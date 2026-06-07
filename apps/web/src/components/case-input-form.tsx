'use client';

import { useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useJudgeCounsel } from '@/context/judge-counsel-context';
import { apiService } from '@/services/api';
import {
  Button,
  Textarea,
  Alert,
  AlertDescription,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  cn,
} from '@lexicon/design-system';
import { AlertCircle, ArrowUpRight, ArrowRight } from 'lucide-react';
import { normalizeMessage } from '@/lib/mappers';
import { createPacedMessageController, getMessageAgentId } from '@/lib/paced-stream';
import type {
  AgentId,
  CaseType,
  CreateSessionRequest,
  CreateSessionStreamEventData,
  DeliberationMessage,
} from '@/types/api';
import { StagedProgress } from '@/components/staged-progress';
import { useModifierKey } from '@/lib/use-modifier-key';

const EXAMPLE_CASES = [
  {
    title: 'Narkotika — penyalahgunaan untuk diri sendiri',
    summary: '5 gram sabu-sabu, pelaku pertama kali, klaim untuk pemakaian pribadi',
    facts:
      'Terdakwa ditemukan dengan 5 gram sabu-sabu, pelaku pertama kali, mengklaim untuk penggunaan pribadi. Terdakwa berusia 28 tahun, karyawan swasta tanpa catatan kriminal sebelumnya. Barang bukti ditemukan di saku celana saat penggerebekan di sebuah klub malam.',
  },
  {
    title: 'Korupsi — penyalahgunaan dana desa',
    summary: 'Kepala desa menggunakan Rp 500 juta untuk keperluan pribadi',
    facts:
      'Terdakwa selaku Kepala Desa didakwa menyalahgunakan Dana Desa sebesar Rp 500.000.000 untuk kepentingan pribadi. Terdakwa menjabat selama 4 tahun, dana digunakan untuk renovasi rumah pribadi dan pembelian kendaraan. Kerugian negara telah dihitung oleh BPKP (Badan Pengawasan Keuangan dan Pembangunan).',
  },
];

const CASE_TYPE_LABEL: Record<CaseType, string> = {
  narcotics: 'Perkara Narkotika',
  corruption: 'Perkara Korupsi',
  general_criminal: 'Perkara Pidana Umum',
  other: 'Perkara Lain',
};

const AGENT_DISPLAY_NAMES: Record<AgentId, string> = {
  strict: 'Legalis',
  humanist: 'Humanis',
  historian: 'Sejarawan',
};

/**
 * Pure keyword-sniff that classifies the typed facts into one of the four
 * case types the backend expects. Lifted out of the submit handler so the
 * realtime "Terbaca sebagai…" chip can use the same logic.
 *
 * This is intentionally simple — a heuristic, not classification. Users
 * override it inline if it gets the framing wrong.
 */
function detectCaseType(text: string): CaseType {
  const t = text.toLowerCase();
  if (/\b(sabu|narcotics|narkotika|ganja|psikotropika)\b/.test(t)) return 'narcotics';
  if (/\b(corruption|korupsi|funds|dana(?!\s+adat)|gratifikasi|tipikor)\b/.test(t))
    return 'corruption';
  return 'general_criminal';
}

interface CaseInputFormProps {
  onSubmit?: (facts: string) => void;
}

export function CaseInputForm({ onSubmit }: CaseInputFormProps) {
  const router = useRouter();
  const {
    setCaseFacts,
    setSessionId,
    setMessages,
    setParsedCase,
    setSimilarCases,
    setOpinion,
    setCurrentPhase,
    setPhaseMetadata,
    setInitialStreamPending,
  } = useJudgeCounsel();
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [streamStatus, setStreamStatus] = useState<string | null>(null);
  const [facts, setFacts] = useState('');
  // When the user manually overrides the inferred case type, we honor that
  // through submit. `null` means "use the inferred type."
  const [override, setOverride] = useState<CaseType | null>(null);
  const surfaceRef = useRef<HTMLDivElement>(null);
  const { glyph: modifierGlyph, isMac } = useModifierKey();

  // Inferred type recomputes on every facts change (cheap — just a regex).
  // Cleared override survives until the user changes it again or submits.
  const inferredType = useMemo(() => detectCaseType(facts), [facts]);
  const effectiveType = override ?? inferredType;

  const handleExample = (text: string) => {
    setFacts(text);
    setOverride(null);
    const el = surfaceRef.current;
    if (!el) return;
    el.classList.remove('anim-paper-highlight');
    void el.offsetWidth;
    el.classList.add('anim-paper-highlight');
    window.setTimeout(() => el.classList.remove('anim-paper-highlight'), 800);
  };

  const charCount = facts.length;
  const wordCount = facts.trim() ? facts.trim().split(/\s+/).length : 0;
  const hasEnoughText = facts.trim().length >= 20;
  const isReady = hasEnoughText && !submitting;
  const showInferenceChip = hasEnoughText;

  const setCreatedSession = (
    sessionId: string,
    parsedCase?: CreateSessionStreamEventData['parsed_case'],
    similarCases?: CreateSessionStreamEventData['similar_cases'],
  ) => {
    setCaseFacts(facts);
    setSessionId(sessionId);
    if (parsedCase) setParsedCase(parsedCase);
    setSimilarCases(similarCases ?? []);
    setOpinion(null);
    setCurrentPhase(null);
    setPhaseMetadata(null);
    setInitialStreamPending(false);
    onSubmit?.(facts);
  };

  const openChamber = (sessionCreated: boolean) => {
    if (!sessionCreated) return false;
    router.push('/deliberation');
    return true;
  };

  const setAgentCompleteMessage = (
    event: CreateSessionStreamEventData,
    sessionId: string,
    pacedMessages: ReturnType<typeof createPacedMessageController>,
  ) => {
    const message: DeliberationMessage | null =
      event.initial_message ??
      (event.agent_id && (event.full_content || event.content)
        ? {
            id: event.message_id || `agent-${event.agent_id}-${Date.now()}`,
            session_id: sessionId,
            sender: { type: 'agent' as const, agent_id: event.agent_id },
            content: event.full_content || event.content || '',
            cited_cases: [],
            cited_laws: [],
            timestamp: new Date().toISOString(),
          }
        : null);

    if (!message) return;

    const agentId = getMessageAgentId(message) ?? event.agent_id;
    if (agentId) {
      pacedMessages.complete(agentId, message);
      return;
    }

    setMessages((prev) => [...prev, normalizeMessage(message)]);
  };

  const openLegacySession = async (requestData: CreateSessionRequest) => {
    const response = await apiService.createSession(requestData);

    setCaseFacts(facts);
    setSessionId(response.session_id);
    setParsedCase(response.parsed_case);
    setSimilarCases(response.similar_cases);
    setOpinion(null);
    setCurrentPhase(null);
    setPhaseMetadata(null);
    setInitialStreamPending(Boolean(response.initial_message));

    if (response.initial_message) {
      setMessages([normalizeMessage(response.initial_message)]);
    }

    onSubmit?.(facts);
    router.push('/deliberation');
  };

  const submitCase = async () => {
    if (!isReady) return;

    const requestData: CreateSessionRequest = {
      case_summary: facts,
      case_type: effectiveType,
      input_type: 'text_summary',
    };

    let createdSessionId: string | null = null;
    let openedChamber = false;
    let streamError: Error | null = null;
    const pacedMessages = createPacedMessageController(setMessages);

    setSubmitting(true);
    setSubmitError(null);
    setStreamStatus('Mempersiapkan ruang musyawarah');
    setMessages([]);

    try {
      await apiService.streamCreateSession(
        requestData,
        (event) => {
          switch (event.event_type) {
            case 'status':
              setStreamStatus(event.status || event.content || 'Menyiapkan bahan musyawarah');
              break;

            case 'session_created': {
              if (!event.session_id) return;
              createdSessionId = event.session_id;
              setCreatedSession(event.session_id, event.parsed_case, event.similar_cases);
              setStreamStatus('Ruang musyawarah siap');
              openedChamber = openChamber(true);
              break;
            }

            case 'agent_start': {
              const agentId = event.agent_id;
              if (!agentId) return;
              setStreamStatus(`${AGENT_DISPLAY_NAMES[agentId] || agentId} mulai menulis`);
              pacedMessages.start({
                agentId,
                sessionId: createdSessionId ?? event.session_id ?? '',
                senderName: AGENT_DISPLAY_NAMES[agentId] || agentId,
              });
              break;
            }

            case 'chunk': {
              const agentId = event.agent_id;
              const content = event.content;
              if (!agentId || !content) return;
              pacedMessages.append(agentId, content);
              break;
            }

            case 'agent_complete':
              setAgentCompleteMessage(
                event,
                createdSessionId ?? event.session_id ?? '',
                pacedMessages,
              );
              break;

            case 'session_complete':
              if (event.session_id && !createdSessionId) {
                createdSessionId = event.session_id;
                setCreatedSession(event.session_id, event.parsed_case, event.similar_cases);
                openedChamber = openChamber(true);
              }
              setAgentCompleteMessage(
                event,
                createdSessionId ?? event.session_id ?? '',
                pacedMessages,
              );
              setInitialStreamPending(Boolean(event.initial_message));
              break;

            case 'error':
              streamError = new Error(event.content || 'Gagal membuka ruang musyawarah');
              if (event.agent_id) {
                pacedMessages.cancel(event.agent_id, { removeMessage: true });
              }
              throw streamError;
          }
        },
        () => {},
        (err) => {
          streamError = err;
        },
      );

      if (streamError && !openedChamber) {
        pacedMessages.cancelAll({ removeMessages: true });
        await openLegacySession(requestData);
        openedChamber = true;
      }
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Failed to create session');
      console.error('Failed to create session:', err);
    } finally {
      if (!openedChamber) {
        setSubmitting(false);
        setStreamStatus(null);
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await submitCase();
  };

  const handleShortcutKeyDown = (e: React.KeyboardEvent<HTMLFormElement>) => {
    const usesPrimaryModifier = isMac ? e.metaKey : e.ctrlKey;
    if (usesPrimaryModifier && e.key === 'Enter') {
      e.preventDefault();
      void submitCase();
    }
  };

  return (
    <div className='grid gap-12 lg:grid-cols-[minmax(0,1fr)_18rem]'>
      {/* PRIMARY — the dossier sheet */}
      <section className='anim-folio-rise-delay-1'>
        <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
          Lembar fakta perkara
        </p>
        <p className='mt-3 max-w-prose text-[0.9375rem] leading-relaxed text-foreground/85'>
          Tuliskan ringkasan dakwaan dengan kata-kata Anda sendiri. Tiga hakim akan membacanya dari
          perspektif yang berbeda, lalu Anda memimpin musyawarah sebagai Hakim Ketua.
        </p>

        <form onSubmit={handleSubmit} onKeyDown={handleShortcutKeyDown} className='mt-6'>
          <div
            ref={surfaceRef}
            className={cn(
              'relative rounded-md border border-paper-edge bg-paper transition-flow',
              'focus-within:border-foreground/30 focus-within:shadow-sm',
            )}
          >
            <div className='flex items-center justify-between border-b border-paper-edge/70 px-4 py-2 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
              <span className='font-folio'>Fakta · ditulis Hakim Ketua</span>
              <span className='font-folio tabular-nums'>
                {wordCount} kata
                <span aria-hidden> · </span>
                {charCount} karakter
              </span>
            </div>
            <Textarea
              placeholder='Contoh: Terdakwa ditemukan dengan 5 gram sabu-sabu, pelaku pertama kali, mengklaim untuk penggunaan pribadi…'
              value={facts}
              onChange={(e) => setFacts(e.target.value)}
              className='min-h-[280px] resize-none border-0 bg-transparent p-5 text-[0.9375rem] leading-7 text-foreground shadow-none placeholder:text-muted-foreground/70 focus-visible:ring-0'
            />
          </div>

          {/* Inferred case-type chip — shows up once there's enough text to
              guess. Lets the user correct the inference before submit so the
              backend gets the framing right. */}
          {showInferenceChip && (
            <div className='mt-3 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-muted-foreground'>
              <span>Terbaca sebagai</span>
              <span className='inline-flex items-center gap-1.5'>
                <span aria-hidden className='inline-block size-1.5 rounded-full bg-foreground/60' />
                <span className='font-folio text-foreground/85'>
                  {CASE_TYPE_LABEL[effectiveType]}
                </span>
              </span>
              <span aria-hidden className='text-muted-foreground/50'>
                ·
              </span>
              <Select value={effectiveType} onValueChange={(v) => setOverride(v as CaseType)}>
                <SelectTrigger
                  className='h-auto w-auto min-w-0 border-0 bg-transparent px-1 py-0 text-xs text-muted-foreground shadow-none transition-snap hover:text-foreground focus:ring-0'
                  aria-label='Ubah jenis perkara'
                >
                  <span className='border-b border-dotted border-foreground/30'>
                    {override ? 'ubah jenis' : 'tidak tepat?'}
                  </span>
                </SelectTrigger>
                <SelectContent align='start'>
                  <SelectItem value='narcotics'>Perkara Narkotika</SelectItem>
                  <SelectItem value='corruption'>Perkara Korupsi</SelectItem>
                  <SelectItem value='general_criminal'>Perkara Pidana Umum</SelectItem>
                  <SelectItem value='other'>Perkara Lain</SelectItem>
                </SelectContent>
              </Select>
              {override && (
                <button
                  type='button'
                  onClick={() => setOverride(null)}
                  className='press text-muted-foreground transition-snap hover:text-foreground'
                >
                  · pakai bacaan otomatis
                </button>
              )}
            </div>
          )}

          {submitError && (
            <Alert variant='destructive' className='mt-4'>
              <AlertCircle />
              <AlertDescription>{submitError}</AlertDescription>
            </Alert>
          )}

          <div className='mt-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between'>
            <p className='text-xs text-muted-foreground'>
              {hasEnoughText ? (
                <>
                  Tekan{' '}
                  <kbd className='rounded border border-paper-edge bg-paper px-1.5 py-0.5 font-folio text-[0.6875rem] text-foreground/70'>
                    {modifierGlyph}
                  </kbd>
                  <span aria-hidden className='mx-0.5 text-muted-foreground/60'>
                    +
                  </span>
                  <kbd className='rounded border border-paper-edge bg-paper px-1.5 py-0.5 font-folio text-[0.6875rem] text-foreground/70'>
                    Enter
                  </kbd>{' '}
                  untuk langsung membuka musyawarah.
                </>
              ) : (
                <>
                  Tulis sedikitnya 20 karakter agar dewan punya konteks awal
                  <span aria-hidden className='mx-1 text-muted-foreground/60'>
                    ·
                  </span>
                  <span className='font-folio text-foreground/70'>
                    {Math.max(0, 20 - charCount)} lagi
                  </span>
                </>
              )}
            </p>

            <Button
              type='submit'
              disabled={!isReady}
              aria-keyshortcuts={isMac ? 'Meta+Enter' : 'Control+Enter'}
              className='press group relative h-11 w-full px-5 text-sm transition-flow disabled:pointer-events-none disabled:bg-muted disabled:text-muted-foreground disabled:opacity-60 sm:w-auto'
            >
              {submitting ? (
                <StagedProgress
                  variant='inline'
                  running={submitting}
                  intervalMs={1500}
                  phases={
                    streamStatus
                      ? [streamStatus]
                      : ['Membaca dakwaan', 'Mencari kasus serupa', 'Membuka ruang musyawarah']
                  }
                />
              ) : (
                <>
                  Buka Musyawarah
                  <ArrowRight className='size-4 transition-snap group-hover:translate-x-0.5' />
                </>
              )}
            </Button>
          </div>
        </form>
      </section>

      <aside className='anim-folio-rise-delay-2 lg:pt-7'>
        <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
          Mulai dari contoh
        </p>
        <ul className='mt-4 divide-y divide-paper-edge border-t border-paper-edge'>
          {EXAMPLE_CASES.map((example) => (
            <li key={example.title}>
              <button
                type='button'
                onClick={() => handleExample(example.facts)}
                className='press group flex w-full flex-col gap-1 py-4 text-left transition-snap hover:bg-paper/60'
              >
                <span className='flex items-center justify-between gap-3'>
                  <span className='font-rethink text-[0.9375rem] font-medium leading-tight text-foreground'>
                    {example.title}
                  </span>
                  <ArrowUpRight className='size-3.5 shrink-0 text-muted-foreground/60 transition-snap group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-foreground' />
                </span>
                <span className='text-[0.8125rem] leading-relaxed text-muted-foreground'>
                  {example.summary}
                </span>
              </button>
            </li>
          ))}
        </ul>

        <p className='mt-6 text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
          Catatan
        </p>
        <p className='mt-2 max-w-[28ch] text-xs leading-relaxed text-muted-foreground'>
          Unggah dokumen PDF perkara akan tersedia pada pembaruan berikutnya.
        </p>
      </aside>
    </div>
  );
}
