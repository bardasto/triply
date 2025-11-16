/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Production Logger (Pino)
 * Structured logging с ротацией файлов и pretty print для development
 * ═══════════════════════════════════════════════════════════════════════════
 */

import pino from 'pino';
import config from '../config/env.js';
import path from 'path';
import fs from 'fs';

// ═══════════════════════════════════════════════════════════════════════════
// Создать папку для логов если не существует
// ═══════════════════════════════════════════════════════════════════════════

const logDir = path.dirname(config.LOG_FILE_PATH);
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// ═══════════════════════════════════════════════════════════════════════════
// Pino Transport Configuration
// ═══════════════════════════════════════════════════════════════════════════

const transport = config.isDev
  ? {
      target: 'pino-pretty',
      options: {
        colorize: true,
        translateTime: 'HH:MM:ss.l',
        ignore: 'pid,hostname',
        singleLine: false,
        messageFormat: '{levelLabel} - {msg}',
      },
    }
  : {
      targets: [
        {
          target: 'pino/file',
          options: { destination: config.LOG_FILE_PATH },
          level: config.LOG_LEVEL,
        },
        {
          target: 'pino/file',
          options: { destination: 1 }, // stdout
          level: 'info',
        },
      ],
    };

// ═══════════════════════════════════════════════════════════════════════════
// Create Logger Instance
// ═══════════════════════════════════════════════════════════════════════════

const logger = pino(
  {
    level: config.LOG_LEVEL,
    base: {
      env: config.NODE_ENV,
      service: 'triply-workers',
    },
    timestamp: pino.stdTimeFunctions.isoTime,
    formatters: {
      level: (label) => {
        return { level: label };
      },
    },
    serializers: {
      err: pino.stdSerializers.err,
      error: pino.stdSerializers.err,
    },
  },
  pino.transport(transport)
);

// ═══════════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Create child logger with context
 */
export const createLogger = (context: string, metadata?: Record<string, any>) => {
  return logger.child({ context, ...metadata });
};

/**
 * Log API call
 */
export const logApiCall = (
  service: string,
  method: string,
  url: string,
  statusCode?: number,
  duration?: number,
  error?: Error
) => {
  const log = logger.child({ service, method, url, statusCode, duration });

  if (error) {
    log.error({ err: error }, `API call failed: ${service} ${method} ${url}`);
  } else {
    log.info(`API call success: ${service} ${method} ${url}`);
  }
};

/**
 * Log job execution
 */
export const logJob = (
  jobName: string,
  status: 'started' | 'success' | 'failed',
  metadata?: Record<string, any>,
  error?: Error
) => {
  const log = logger.child({ job: jobName, ...metadata });

  switch (status) {
    case 'started':
      log.info(`Job started: ${jobName}`);
      break;
    case 'success':
      log.info(`Job completed: ${jobName}`);
      break;
    case 'failed':
      log.error({ err: error }, `Job failed: ${jobName}`);
      break;
  }
};

/**
 * Log database operation
 */
export const logDb = (
  operation: string,
  table: string,
  success: boolean,
  duration?: number,
  rowsAffected?: number,
  error?: Error
) => {
  const log = logger.child({ operation, table, duration, rowsAffected });

  if (success) {
    log.debug(`DB operation success: ${operation} ${table}`);
  } else {
    log.error({ err: error }, `DB operation failed: ${operation} ${table}`);
  }
};

/**
 * Log generation event
 */
export const logGeneration = (
  type: 'trip' | 'poi' | 'image',
  action: 'started' | 'completed' | 'failed',
  metadata?: Record<string, any>,
  error?: Error
) => {
  const log = logger.child({ type, action, ...metadata });

  if (action === 'failed') {
    log.error({ err: error }, `Generation failed: ${type}`);
  } else {
    log.info(`Generation ${action}: ${type}`);
  }
};

/**
 * Log rate limit hit
 */
export const logRateLimit = (
  service: string,
  limit: number,
  remaining: number,
  resetAt?: Date
) => {
  logger.warn(
    { service, limit, remaining, resetAt },
    `Rate limit approaching for ${service}`
  );
};

/**
 * Log cache hit/miss
 */
export const logCache = (
  key: string,
  hit: boolean,
  ttl?: number,
  metadata?: Record<string, any>
) => {
  const log = logger.child({ key, hit, ttl, ...metadata });
  log.debug(`Cache ${hit ? 'hit' : 'miss'}: ${key}`);
};

// ═══════════════════════════════════════════════════════════════════════════
// Error Handler Middleware
// ═══════════════════════════════════════════════════════════════════════════

export const handleError = (error: Error, context?: string) => {
  const log = context ? logger.child({ context }) : logger;
  
  log.error(
    {
      err: error,
      stack: error.stack,
      name: error.name,
      message: error.message,
    },
    `Unhandled error${context ? ` in ${context}` : ''}`
  );

  // Send to Sentry if configured
  if (config.SENTRY_DSN) {
    // TODO: Integrate Sentry SDK
    // Sentry.captureException(error);
  }
};

/**
 * Graceful shutdown logger
 */
export const logShutdown = (signal: string) => {
  logger.info(`Received ${signal}, shutting down gracefully...`);
};

// ═══════════════════════════════════════════════════════════════════════════
// Startup Log
// ═══════════════════════════════════════════════════════════════════════════

if (config.isDev) {
  logger.info('🚀 Logger initialized');
  logger.info(`📍 Log level: ${config.LOG_LEVEL}`);
  logger.info(`📍 Log file: ${config.LOG_FILE_PATH}`);
}

// ═══════════════════════════════════════════════════════════════════════════
// Export
// ═══════════════════════════════════════════════════════════════════════════

export default logger;
