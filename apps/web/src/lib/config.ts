const BACKEND_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://api.lexicon.id';

export const config = {
  api: {
    baseUrl: BACKEND_URL,
    apiKey: process.env.NEXT_PUBLIC_LEXICON_API_KEY || '',
    timeout: 30000,
  },
} as const;
