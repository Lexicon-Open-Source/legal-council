import { render, screen, within } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { LegalOpinion } from './legal-opinion';
import type { UIDeliberationMessage } from '@/lib/mappers';
import type { LegalOpinionDraft } from '@/types/api';

vi.mock('@/services/api', () => ({
  apiService: {
    downloadDeliberationPdf: vi.fn(),
    triggerDownload: vi.fn(),
  },
}));

const baseOpinion: LegalOpinionDraft = {
  session_id: 'sess_1',
  case_summary: 'Perkara korupsi dana desa.',
  verdict_recommendation: {
    decision: 'guilty',
    confidence: 'high',
    reasoning: 'Terdakwa terbukti menyalahgunakan kewenangan.',
  },
  sentence_recommendation: {
    imprisonment_months: {
      minimum: 12,
      maximum: 24,
      recommended: 18,
    },
    fine_idr: {
      minimum: 0,
      maximum: 0,
      recommended: 0,
    },
    additional_penalties: [],
  },
  legal_arguments: {
    for_conviction: [
      {
        argument: 'Semua argumen legal opinion salah diberi source_agent Legalis.',
        source_agent: 'strict',
        supporting_cases: [],
        strength: 'strong',
      },
    ],
    for_leniency: [
      {
        argument: 'Argumen keringanan juga salah diberi source_agent Legalis.',
        source_agent: 'strict',
        supporting_cases: [],
        strength: 'moderate',
      },
    ],
    for_severity: [
      {
        argument: 'Argumen pemberatan juga salah diberi source_agent Legalis.',
        source_agent: 'strict',
        supporting_cases: [],
        strength: 'strong',
      },
    ],
  },
  applicable_laws: [],
  cited_precedents: [],
  dissenting_views: [],
  generated_at: '2026-04-29T00:00:00.000Z',
};

const messages: UIDeliberationMessage[] = [
  {
    id: 'msg_legalis',
    session_id: 'sess_1',
    sender: 'strict',
    sender_name: 'Legalis',
    content: '- Unsur melawan hukum dan kerugian negara telah terpenuhi.',
    timestamp: new Date('2026-04-29T00:00:00.000Z'),
  },
  {
    id: 'msg_humanis',
    session_id: 'sess_1',
    sender: 'humanist',
    sender_name: 'Humanis',
    content:
      'Selamat pagi, rekan-rekan Hakim yang terhormat. Kita saat ini dihadapkan pada perkara serius penyalahgunaan Dana Desa oleh seorang Kepala Desa senilai Rp 500.000.000, yang menurut laporan BPKP telah mengakibatkan kerugian negara. Prinsip rehabilitasi dan pemulihan kerugian tetap perlu ditimbang.',
    timestamp: new Date('2026-04-29T00:00:00.000Z'),
  },
  {
    id: 'msg_sejarawan',
    session_id: 'sess_1',
    sender: 'historian',
    sender_name: 'Sejarawan',
    content: '- Putusan sejenis menunjukkan pidana proporsional bergantung pada nilai kerugian.',
    timestamp: new Date('2026-04-29T00:00:00.000Z'),
  },
];

describe('LegalOpinion', () => {
  it('shows all three judge perspectives from the transcript when source_agent is collapsed', () => {
    render(<LegalOpinion opinion={baseOpinion} messages={messages} onReset={vi.fn()} />);

    const section = screen
      .getByText('Argumen utama dari tiga perspektif')
      .closest('section') as HTMLElement;

    expect(within(section).getByRole('heading', { name: 'Legalis' })).toBeTruthy();
    expect(within(section).getByRole('heading', { name: 'Humanis' })).toBeTruthy();
    expect(within(section).getByRole('heading', { name: 'Sejarawan' })).toBeTruthy();
    expect(within(section).getByText(/Rp 500\.000\.000/)).toBeTruthy();
    expect(within(section).queryByText(/Selamat pagi/)).toBeNull();
    expect(within(section).queryByText(/^000,/)).toBeNull();
    expect(within(section).getByText(/Putusan sejenis/)).toBeTruthy();
  });
});
