export function notificationTarget(sourceType, role, allowedViews) {
  const targets = {
    incoming_letters: "Surat Masuk", email_messages: "Surat Masuk",
    dispositions: role === "User" ? "Disposisi Masuk" : "Disposisi",
    letter_requests: role === "Operator" ? "Ajuan Masuk" : role === "Pimpinan" ? "Approval" : "Ajuan Surat",
    outgoing_letters: role === "Pimpinan" ? "Approval" : "Surat Keluar",
    backups: "Backup", users: "Pengguna"
  };
  const target = targets[sourceType];
  return allowedViews.includes(target) ? target : null;
}
