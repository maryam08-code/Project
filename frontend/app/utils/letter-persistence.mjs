// Approval/final forms expose the same file through a singular field and a list.
// Send its bytes once so a valid 10 MB PDF fits the API's 15 MB JSON limit.
export function compactLetterPayload(record) {
  const payload = { ...record };
  for (const [single, list] of [
    ['dokumenApprovalPimpinan', 'lampiranApproval'],
    ['suratFinalOperator', 'lampiranFinal'],
    ['dokumenPendukungRevisi', 'lampiranRevisiDraft']
  ]) {
    const attachment = payload[single];
    if (!attachment) continue;
    if (payload[list]?.some(item => attachment[3] ? item?.[3] === attachment[3] : attachment[6] && item?.[6] === attachment[6])) delete payload[single];
  }
  return payload;
}

export function letterIdentityKey(record) {
  if (record?.id) return `database:${record.id}`;
  return [record?.ownerId || record?.pemohon || '', record?.jenis || '', record?.judul || record?.keterangan || '', record?.tujuan || '']
    .map(value => String(value).trim().toLowerCase()).join('|');
}
