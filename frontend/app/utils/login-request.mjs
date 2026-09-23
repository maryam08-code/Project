// Only the read-only readiness probe is retried; a login POST is sent once.
export async function requestLogin(baseUrl, username, password, {
  fetchImpl = globalThis.fetch,
  wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
  attempts = 8,
  probeTimeoutMs = 1500,
  loginTimeoutMs = 15000
} = {}) {
  let ready = false;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      const response = await fetchImpl(`${baseUrl}/health`, {
        cache: "no-store", signal: AbortSignal.timeout(probeTimeoutMs)
      });
      ready = response.ok;
    } catch { /* Backend may still be starting or reconnecting. */ }
    if (ready) break;
    if (attempt < attempts - 1) await wait(500);
  }
  if (!ready) throw new Error("Server belum tersedia. Silakan klik Login lagi beberapa saat lagi, tanpa perlu refresh halaman.");

  let response;
  try {
    response = await fetchImpl(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password }),
      signal: AbortSignal.timeout(loginTimeoutMs)
    });
  } catch {
    throw new Error("Koneksi login terputus atau server belum merespons. Silakan klik Login lagi tanpa perlu refresh halaman.");
  }
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(payload.message || "Login gagal. Silakan coba lagi.");
  if (!payload.token || !payload.user) throw new Error("Respons login tidak valid. Silakan coba lagi.");
  return payload;
}
