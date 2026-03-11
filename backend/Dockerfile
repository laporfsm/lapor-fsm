# Gunakan official Bun image
FROM oven/bun:latest

# Set working directory
WORKDIR /app

# Copy package files (untuk cache dependencies)
COPY package.json bun.lock ./

# Install dependencies
RUN bun install

# Copy sisa source code
COPY . .

# Ensure uploads directory exists (used as temp buffer for file uploads)
RUN mkdir -p /app/uploads

# Set Environment Variable untuk Port (Koyeb injects PORT, but good to have default)
ENV PORT=3000

# Expose port
EXPOSE 3000

# Jalankan aplikasi
CMD ["bun", "run", "start"]
