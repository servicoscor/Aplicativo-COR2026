/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable React strict mode for development
  reactStrictMode: true,

  // Environment variables that will be available on the client
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  },

  // Disable image optimization for simplicity (can be enabled later)
  images: {
    unoptimized: true,
  },
}

module.exports = nextConfig
