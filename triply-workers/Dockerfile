# ═══════════════════════════════════════════════════════════════════════════
# Triply AI API - Production Dockerfile
# Uses tsx for TypeScript execution (simpler, reliable)
# ═══════════════════════════════════════════════════════════════════════════

FROM node:20-alpine

WORKDIR /app

# Set production environment
ENV NODE_ENV=production

# Copy package files
COPY package*.json ./

# Install all dependencies (tsx needed for runtime)
RUN npm ci && npm cache clean --force

# Copy source code
COPY src ./src
COPY tsconfig.json ./

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the server using tsx
CMD ["npx", "tsx", "src/api/server.ts"]
