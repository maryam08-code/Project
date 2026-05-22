import "./globals.css";

export const metadata = {
  title: "E-Office Persuratan",
  description: "Aplikasi E-Office untuk pengelolaan surat masuk, surat keluar, disposisi, arsip, dan laporan."
};

export default function RootLayout({ children }) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
