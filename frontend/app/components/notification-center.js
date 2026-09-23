"use client";

import { createContext, useCallback, useContext, useEffect, useRef, useState } from "react";
import { notificationTarget } from "../utils/notification-target.mjs";

const NotificationContext = createContext(null);
const emptyMeta = { unreadCount: 0, totalCount: 0, totalPages: 1 };

export function NotificationProvider({ request, role, allowedViews, onNavigate, children }) {
  const [items, setItems] = useState([]);
  const [latest, setLatest] = useState([]);
  const [meta, setMeta] = useState(emptyMeta);
  const [unreadCount, setUnreadCount] = useState(0);
  const [page, setPage] = useState(1);
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [revision, setRevision] = useState(0);
  const mounted = useRef(true);
  const mutation = useRef(false);
  const generation = useRef(0);
  const refresh = useCallback(() => setRevision(value => value + 1), []);

  useEffect(() => {
    mounted.current = true;
    return () => { mounted.current = false; generation.current += 1; };
  }, []);

  useEffect(() => {
    let disposed = false;
    let controller;
    let running = false;
    async function load(initial = false) {
      if (running || (document.hidden && !initial)) return;
      running = true;
      controller = new AbortController();
      const current = ++generation.current;
      if (initial) setLoading(true);
      try {
        const options = { signal: AbortSignal.any([controller.signal, AbortSignal.timeout(10000)]), cache: "no-store" };
        const [listing, summary] = await Promise.all([
          request(`/notifications?page=${page}&perPage=10&unreadOnly=${unreadOnly}`, options),
          request("/notifications?page=1&perPage=3", options)
        ]);
        if (disposed || current !== generation.current) return;
        if (page > listing.meta.totalPages) { setPage(listing.meta.totalPages); return; }
        setItems(listing.data);
        setMeta(listing.meta);
        setLatest(summary.data);
        setUnreadCount(summary.meta.unreadCount);
        setError("");
      } catch (err) {
        if (!disposed && current === generation.current) setError(err.message || "Notifikasi gagal dimuat.");
      } finally {
        running = false;
        if (!disposed && current === generation.current) setLoading(false);
      }
    }
    load(true);
    const timer = setInterval(() => load(), 30000);
    const resume = () => load();
    window.addEventListener("focus", resume);
    window.addEventListener("online", resume);
    document.addEventListener("visibilitychange", resume);
    return () => {
      disposed = true;
      controller?.abort();
      clearInterval(timer);
      window.removeEventListener("focus", resume);
      window.removeEventListener("online", resume);
      document.removeEventListener("visibilitychange", resume);
    };
  }, [request, page, unreadOnly, revision]);

  async function markRead(notification, navigate = false) {
    if (mutation.current) return;
    mutation.current = true;
    setBusy(true);
    setError("");
    try {
      if (!notification.is_read) {
        await request(`/notifications/${encodeURIComponent(notification.id)}/read`, { method: "POST" });
      }
      if (!mounted.current) return;
      refresh();
      if (navigate) {
        const target = notificationTarget(notification.source_type, role, allowedViews);
        if (target) onNavigate(target);
      }
    } catch (err) {
      if (mounted.current) setError(err.message);
    } finally {
      mutation.current = false;
      if (mounted.current) setBusy(false);
    }
  }

  async function markAll() {
    if (mutation.current) return;
    mutation.current = true;
    setBusy(true);
    setError("");
    try {
      await request("/notifications/read-all", { method: "POST" });
      if (mounted.current) { setPage(1); refresh(); }
    } catch (err) {
      if (mounted.current) setError(err.message);
    } finally {
      mutation.current = false;
      if (mounted.current) setBusy(false);
    }
  }

  return <NotificationContext.Provider value={{ items, latest, meta, unreadCount, page, setPage,
    unreadOnly, setUnreadOnly, loading, error, busy, refresh, markRead, markAll,
    role, allowedViews, onNavigate }}>{children}</NotificationContext.Provider>;
}

export function NotificationBell() {
  const { unreadCount, onNavigate } = useContext(NotificationContext);
  return <button type="button" className="portalNotificationBell" onClick={() => onNavigate("Notifikasi")}
    aria-label={`Notifikasi, ${unreadCount} belum dibaca`} title="Notifikasi">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
      <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" />
    </svg>
    {unreadCount > 0 && <span className="portalNotificationBadge">{unreadCount > 99 ? "99+" : unreadCount}</span>}
  </button>;
}

function NotificationItems({ items }) {
  const { busy, markRead, role, allowedViews } = useContext(NotificationContext);
  if (!items.length) return <p className="portalNotificationEmpty">Belum ada notifikasi pada daftar ini.</p>;
  return <ul className="portalNotificationList">{items.map(item => {
    const target = notificationTarget(item.source_type, role, allowedViews);
    const date = new Date(item.created_at);
    return <li key={item.id} className={item.is_read ? "" : "isUnread"}>
      <div className="portalNotificationText">
        <strong>{!item.is_read && <span className="portalUnreadDot" aria-label="Belum dibaca" />}{item.title}</strong>
        <p>{item.message}</p>
        <time dateTime={item.created_at}>{Number.isNaN(date.getTime()) ? "" : new Intl.DateTimeFormat("id-ID", {
          dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Jakarta"
        }).format(date)} WIB</time>
      </div>
      <div className="portalNotificationItemActions">
        {!item.is_read && <button type="button" disabled={busy} onClick={() => markRead(item)}>Tandai dibaca</button>}
        {target && <button type="button" disabled={busy} onClick={() => markRead(item, true)}>Buka {target}</button>}
      </div>
    </li>;
  })}</ul>;
}

export function NotificationDashboard() {
  const { latest, error, loading, onNavigate, refresh } = useContext(NotificationContext);
  return <article className="dashPanel portalNotificationDashboard">
    <div className="portalNotificationHeading"><h3>Notifikasi Terbaru</h3>
      <button type="button" onClick={() => onNavigate("Notifikasi")}>Lihat semua</button></div>
    {error && <p role="alert" className="fieldError">{error} <button type="button" onClick={refresh}>Coba lagi</button></p>}
    {loading && !latest.length ? <p role="status">Memuat notifikasi...</p> : <NotificationItems items={latest} />}
  </article>;
}

export function NotificationPage() {
  const { items, meta, unreadCount, loading, error, busy, refresh, markAll,
    page, setPage, unreadOnly, setUnreadOnly } = useContext(NotificationContext);
  return <section className="notificationPage">
    <div className="dashboardTitle"><h1>Notifikasi</h1><p>Pemberitahuan surat dan pekerjaan untuk akun Anda.</p></div>
    <article className="dashPanel portalNotificationPanel">
      <div className="portalNotificationHeading">
        <div><h3>Daftar Notifikasi</h3><p role="status">{unreadCount} belum dibaca</p></div>
        <div className="portalNotificationActions">
          <button type="button" onClick={refresh} disabled={loading || busy}>Perbarui</button>
          <button type="button" onClick={markAll} disabled={busy || !unreadCount}>Tandai semua dibaca</button>
        </div>
      </div>
      <label className="portalNotificationFilter"><input type="checkbox" checked={unreadOnly}
        onChange={event => { setUnreadOnly(event.target.checked); setPage(1); }} /> Hanya belum dibaca</label>
      {error && <p className="fieldError" role="alert">{error} <button type="button" onClick={refresh}>Coba lagi</button></p>}
      {loading ? <p role="status" className="portalNotificationEmpty">Memuat notifikasi...</p> : <NotificationItems items={items} />}
      <div className="portalNotificationPagination">
        <span>{meta.totalCount} notifikasi · Halaman {page} dari {meta.totalPages}</span>
        <div className="portalNotificationActions">
          <button type="button" disabled={loading || page <= 1} onClick={() => setPage(value => value - 1)}>Sebelumnya</button>
          <button type="button" disabled={loading || page >= meta.totalPages} onClick={() => setPage(value => value + 1)}>Berikutnya</button>
        </div>
      </div>
    </article>
  </section>;
}
