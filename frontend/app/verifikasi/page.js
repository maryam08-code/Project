'use client';

import React, { useState } from 'react';

export default function VerifikasiSuratPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;

    setLoading(true);
    setError('');
    setResult(null);

    try {
      // Encode query agar tanda miring '/' aman
      const safeQuery = encodeURIComponent(encodeURIComponent(searchQuery.trim()));
      const res = await fetch(`/api/public/verify/${safeQuery}`);
      const data = await res.json();

      if (res.ok && data.valid) {
        setResult(data.data);
      } else {
        setError(data.message || 'Surat dengan nomor tersebut tidak ditemukan.');
      }
    } catch (err) {
      console.error(err);
      setError('Gagal terhubung ke server verifikasi.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f8fafc', fontFamily: 'sans-serif', color: '#1e293b' }}>
      
      {/* 1. Navbar Header */}
      <header style={{ backgroundColor: '#ffffff', borderBottom: '1px solid #e2e8f0', padding: '16px 32px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{ width: '40px', height: '40px', backgroundColor: '#fbbf24', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', color: '#ffffff', fontSize: '16px' }}>
            PU
          </div>
          <span style={{ fontSize: '18px', fontWeight: '700', color: '#0f172a' }}>
            E-Office STT Pekerjaan Umum Jakarta
          </span>
        </div>
      </header>

      {/* 2. Content Container */}
      <main style={{ maxWidth: '1100px', margin: '0 auto', padding: '32px 16px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
        
        {/* Title Block */}
        <div style={{ textAlign: 'center' }}>
          <h1 style={{ fontSize: '28px', fontWeight: '800', color: '#1e3a8a', marginBottom: '6px' }}>
            Verifikasi Keabsahan Surat
          </h1>
          <p style={{ fontSize: '14px', color: '#64748b', margin: 0 }}>
            Cek apakah surat benar diterbitkan oleh STT Pekerjaan Umum Jakarta
          </p>
        </div>

        {/* Search Card Box */}
        <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', padding: '28px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)', maxWidth: '850px', margin: '0 auto', width: '100%' }}>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
            <span style={{ width: '24px', height: '24px', backgroundColor: '#2563eb', color: '#ffffff', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 'bold' }}>
              1
            </span>
            <span style={{ fontSize: '14px', fontWeight: '600', color: '#2563eb' }}>
              Masukkan Nomor Surat / Kode Verifikasi
            </span>
          </div>

          <form onSubmit={handleSearch} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Contoh: SK/PUJ/VI/2026/017 atau masukkan kode verifikasi"
                style={{ width: '100%', padding: '14px 16px 14px 42px', border: '1px solid #cbd5e1', borderRadius: '10px', fontSize: '14px', outline: 'none', backgroundColor: '#ffffff', boxSizing: 'border-box' }}
              />
              <span style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }}>
                🔍
              </span>
            </div>

            <div style={{ textAlign: 'center' }}>
              <button
                type="submit"
                disabled={loading}
                style={{ backgroundColor: '#2563eb', color: '#ffffff', fontWeight: '600', padding: '12px 32px', borderRadius: '10px', fontSize: '14px', border: 'none', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: '8px', boxShadow: '0 2px 4px rgba(37,99,235,0.2)' }}
              >
                <span>🛡️</span>
                <span>{loading ? 'Memeriksa...' : 'Verifikasi Surat'}</span>
              </button>
            </div>
          </form>

          <p style={{ textAlign: 'center', fontSize: '12px', color: '#94a3b8', marginTop: '16px', marginBottom: 0 }}>
            ℹ️ Fitur ini digunakan oleh pihak luar untuk memeriksa keaslian surat tanpa harus login ke aplikasi e-office.
          </p>
        </div>

        {/* 3. Hasil Verifikasi */}
        {result && (
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', maxWidth: '1000px', margin: '0 auto', width: '100%' }}>
            
            {/* Sisi Kiri: Detail Surat */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', padding: '24px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
                
                {/* Header Status */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', borderBottom: '1px solid #f1f5f9', paddingBottom: '16px', marginBottom: '20px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '40px', height: '40px', backgroundColor: '#059669', color: '#ffffff', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', fontWeight: 'bold' }}>
                      ✓
                    </div>
                    <div>
                      <h2 style={{ fontSize: '18px', fontWeight: '700', color: '#047857', margin: 0 }}>
                        Surat Terverifikasi
                      </h2>
                      <p style={{ fontSize: '12px', color: '#64748b', margin: '2px 0 0 0' }}>
                        Surat ini valid dan resmi diterbitkan oleh STT Pekerjaan Umum Jakarta.
                      </p>
                    </div>
                  </div>
                  <span style={{ backgroundColor: '#ecfdf5', border: '1px solid #a7f3d0', color: '#047857', fontSize: '11px', fontWeight: '700', padding: '4px 12px', borderRadius: '20px' }}>
                    ✓ VALID / RESMI DITERBITKAN
                  </span>
                </div>

                {/* Grid Detail Info */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', fontSize: '12px', marginBottom: '20px' }}>
                  <div><span style={{ color: '#64748b' }}>Nomor Surat:</span> <br/><strong style={{ fontSize: '13px', color: '#0f172a' }}>{result.nomorSurat}</strong></div>
                  <div><span style={{ color: '#64748b' }}>Instansi Penerbit:</span> <br/><strong style={{ fontSize: '13px', color: '#0f172a' }}>{result.instansiPenerbit}</strong></div>
                  <div><span style={{ color: '#64748b' }}>Tanggal Surat:</span> <br/><strong>{result.tanggalSurat}</strong></div>
                  <div><span style={{ color: '#64748b' }}>Unit/Bagian:</span> <br/><strong>{result.unitBagian}</strong></div>
                  <div><span style={{ color: '#64748b' }}>Jenis Surat:</span> <br/><strong>{result.jenisSurat}</strong></div>
                  <div><span style={{ color: '#64748b' }}>Penandatangan:</span> <br/><strong>{result.penandatangan}</strong></div>
                  <div><span style={{ color: '#64748b' }}>Perihal:</span> <br/><strong>{result.perihal}</strong></div>
                  <div><span style={{ color: '#64748b' }}>Status Verifikasi:</span> <br/><strong style={{ color: '#059669' }}>{result.statusVerifikasi}</strong></div>
                </div>

                {/* Info Tambahan Card */}
                <div style={{ backgroundColor: '#f0fdf4', border: '1px solid #bbf7d0', borderRadius: '12px', padding: '16px', fontSize: '12px', color: '#166534' }}>
                  <div style={{ fontWeight: '700', marginBottom: '8px' }}>ℹ️ Informasi Tambahan</div>
                  <div style={{ marginBottom: '4px' }}>✓ Dokumen tercatat dalam sistem e-office kampus</div>
                  <div style={{ marginBottom: '4px' }}>✓ Nomor surat sesuai dengan arsip digital</div>
                  <div>✓ Surat dapat digunakan sebagai bukti administrasi resmi</div>
                </div>

              </div>
            </div>

            {/* Sisi Kanan: Pratinjau Document Card */}
            <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', padding: '20px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)', height: 'fit-content' }}>
              <div style={{ fontSize: '13px', fontWeight: '700', color: '#334155', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span>📄</span> Pratinjau Surat
              </div>

              <div style={{ backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '16px', textAlign: 'center' }}>
                <div style={{ fontSize: '10px', fontWeight: '800', color: '#334155', letterSpacing: '0.5px' }}>
                  STT PEKERJAAN UMUM JAKARTA
                </div>
                <div style={{ fontSize: '11px', fontWeight: '800', borderBottom: '1px solid #cbd5e1', paddingBottom: '8px', margin: '8px 0' }}>
                  SURAT KETERANGAN<br/>
                  <span style={{ fontSize: '9px', fontWeight: 'normal', color: '#64748b' }}>Nomor: {result.nomorSurat}</span>
                </div>

                {/* Body Lines */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', padding: '12px 0' }}>
                  <div style={{ height: '6px', backgroundColor: '#e2e8f0', borderRadius: '3px', width: '100%' }}></div>
                  <div style={{ height: '6px', backgroundColor: '#e2e8f0', borderRadius: '3px', width: '80%' }}></div>
                  <div style={{ height: '6px', backgroundColor: '#e2e8f0', borderRadius: '3px', width: '100%' }}></div>
                </div>

                {/* Stamp & QR Code */}
                <div style={{ display: 'flex', justifyContent: 'space-around', alignItems: 'center', marginTop: '12px' }}>
                  <div style={{ width: '45px', height: '45px', borderRadius: '50%', border: '2px dashed #60a5fa', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '8px', color: '#3b82f6', fontWeight: 'bold', transform: 'rotate(-10deg)' }}>
                    STEMPEL
                  </div>
                  <div style={{ width: '55px', height: '55px', backgroundColor: '#0f172a', color: '#ffffff', borderRadius: '6px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '8px', fontWeight: 'bold' }}>
                    QR CODE
                  </div>
                </div>
              </div>

              <p style={{ fontSize: '10px', color: '#94a3b8', textAlign: 'center', marginTop: '12px', marginBottom: 0 }}>
                QR Code di atas sesuai dengan data surat.
              </p>
            </div>

          </div>
        )}

        {/* Error Notification */}
        {error && (
          <div style={{ backgroundColor: '#fff1f2', border: '1px solid #fecdd3', color: '#e11d48', padding: '14px', borderRadius: '12px', fontSize: '13px', textAlign: 'center', fontWeight: '600', maxWidth: '600px', margin: '0 auto', width: '100%' }}>
            ⚠️ {error}
          </div>
        )}

      </main>
    </div>
  );
}