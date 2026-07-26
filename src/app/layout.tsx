import type { Metadata } from "next";
import { Instrument_Sans, Dancing_Script } from "next/font/google";
import Providers from "./providers";
import "./globals.css";

const instrumentSans = Instrument_Sans({
  subsets: ["latin"],
  variable: "--font-instrument-sans",
  weight: ["500", "600", "700"],
  display: "swap",
});

// Sadece logo imzası ("Hayallerinizi Tasarlar") için — gerçek logo bir görsel,
// bu kursif font ona en yakın CSS yaklaşımı; gerçek logo dosyası gelince kaldırılabilir.
const dancingScript = Dancing_Script({
  subsets: ["latin"],
  variable: "--font-script",
  weight: ["600"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Özcan Mobilya | Hayallerinizi Tasarlar",
  description:
    "Özcan Mobilya — gardırop, TV ünitesi, dresuar ve daha fazlası. Size özel tasarımlar.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="tr">
      <body
        className={`${instrumentSans.variable} ${dancingScript.variable} font-body text-secondary antialiased`}
      >
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
