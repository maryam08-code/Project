/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    const backendUrl = (process.env.BACKEND_API_URL || "http://127.0.0.1:8000/api").replace(/\/$/, "");
    return { afterFiles: [{ source: "/api/:path*", destination: `${backendUrl}/:path*` }] };
  }
};

export default nextConfig;
