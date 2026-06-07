import { describe, expect, it } from 'vitest';
import { formatTargetedAgentMessage, getApiTargetAgent } from './targeted-agent-message';

describe('formatTargetedAgentMessage', () => {
  it('uses backend-recognized Humanis addressing', () => {
    expect(
      formatTargetedAgentMessage(
        'Humanis, dari sudut pandang rehabilitasi, bagaimana pandangan Anda?',
        'humanist',
      ),
    ).toBe('Hakim Humanis, dari sudut pandang rehabilitasi, bagaimana pandangan Anda?');
  });

  it('uses backend-recognized Sejarawan addressing', () => {
    expect(
      formatTargetedAgentMessage('Sejarawan, apakah ada yurisprudensi yang relevan?', 'historian'),
    ).toBe('Hakim Sejarawan, apakah ada yurisprudensi yang relevan?');
  });

  it('does not duplicate an already explicit judge address', () => {
    expect(formatTargetedAgentMessage('Hakim Humanis, bagaimana pandangan Anda?', 'humanist')).toBe(
      'Hakim Humanis, bagaimana pandangan Anda?',
    );
  });
});

describe('getApiTargetAgent', () => {
  it('uses the Indonesian target-agent aliases from the API contract', () => {
    expect(getApiTargetAgent('strict')).toBe('legalis');
    expect(getApiTargetAgent('humanist')).toBe('humanis');
    expect(getApiTargetAgent('historian')).toBe('sejarawan');
  });
});
