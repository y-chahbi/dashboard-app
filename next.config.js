/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  eslint: {
    // Warning: ESLint 9 has configuration issues with Next.js 15
    // Disable during builds until compatibility is fixed
    ignoreDuringBuilds: true,
  },
};

module.exports = nextConfig;