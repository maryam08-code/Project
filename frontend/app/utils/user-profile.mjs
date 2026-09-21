export function userProfile(user) {
  return {
    name: user?.full_name ?? '',
    username: user?.username ?? '',
    role: user?.role_name ?? '',
    email: user?.email ?? '',
    unit: user?.unit ?? '',
    position: user?.position ?? '',
    status: user?.status === 'aktif' ? 'Aktif' : user?.status === 'nonaktif' ? 'Nonaktif' : ''
  };
}
