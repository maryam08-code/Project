export function ownedRequests(requests, userId) {
  if (!userId) return [];
  return requests.filter((request) => request.ownerId === userId);
}

export function activitySummary(requests, dispositions) {
  const count = (statuses) => requests.filter((item) => statuses.includes(item.status)).length;
  return {
    total: requests.length,
    processing: count(['Menunggu Approval', 'Diproses']),
    approved: count(['Disetujui', 'Selesai']),
    rejected: count(['Ditolak', 'Perlu Revisi']),
    draft: count(['Draft']),
    cancelled: count(['Dibatalkan']),
    newDispositions: dispositions.filter((item) => item.status === 'dikirim').length
  };
}
