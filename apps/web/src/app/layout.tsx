import type { Metadata, Viewport } from 'next';
import { Rethink_Sans } from 'next/font/google';
import { AppLayout } from '@/components/app-layout';
import './globals.css';

const rethinkSans = Rethink_Sans({
  variable: '--font-rethink-sans',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: 'Dewan Hakim | Ruang Musyawarah Virtual',
  description:
    'Panel hakim virtual berbasis AI untuk analisis dan musyawarah perkara hukum yang komprehensif. Jelajahi perspektif ketat, humanis, dan yurisprudensi.',
  keywords: [
    'teknologi hukum',
    'hakim ai',
    'musyawarah hukum',
    'hukum',
    'keadilan',
    'pengadilan virtual',
    'pendapat hukum',
  ],
  authors: [{ name: 'Tim Dewan Hakim' }],
  openGraph: {
    title: 'Dewan Hakim | Ruang Musyawarah Virtual',
    description:
      'Panel hakim virtual berbasis AI untuk analisis dan musyawarah perkara hukum yang komprehensif.',
    url: 'https://judge-counsel.vercel.app', // Placeholder URL
    siteName: 'Dewan Hakim',
    locale: 'id_ID',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Dewan Hakim | Ruang Musyawarah Virtual',
    description:
      'Panel hakim virtual berbasis AI untuk analisis dan musyawarah perkara hukum yang komprehensif.',
  },
  icons: [
    {
      rel: 'icon',
      url: '/favicon/favicon.ico',
    },
    {
      rel: 'apple-touch-icon',
      sizes: '180x180',
      url: '/favicon/apple-touch-icon.png',
    },
    {
      rel: 'icon',
      type: 'image/png',
      sizes: '32x32',
      url: '/favicon/favicon-32x32.png',
    },
    {
      rel: 'icon',
      type: 'image/png',
      sizes: '16x16',
      url: '/favicon/favicon-16x16.png',
    },
  ],
  manifest: '/favicon/site.webmanifest',
};

export const viewport: Viewport = {
  themeColor: '#ffffff',
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang='id'>
      <body className={`${rethinkSans.variable} font-sans antialiased`}>
        <AppLayout>{children}</AppLayout>
      </body>
    </html>
  );
}
