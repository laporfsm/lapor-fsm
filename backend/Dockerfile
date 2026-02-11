# Gunakan official Bun image
FROM oven/bun:latest

# Set working directory
WORKDIR /app

# Copy package files (untuk cache dependencies)
COPY package.json bun.lock ./

# Install dependencies (production mode)
RUN bun install --production

# Copy sisa source code
COPY . .

# Set Environment Variable untuk Port (Koyeb injects PORT, but good to have default)
ENV PORT=3000

# Expose port
EXPOSE 3000

# Jalankan aplikasi
CMD ["bun", "run", "start"]
