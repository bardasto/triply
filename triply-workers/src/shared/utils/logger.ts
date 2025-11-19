/**
 * Simple Logger Utility
 */

type LogLevel = 'info' | 'warn' | 'error' | 'debug';

class Logger {
  private prefix: string;

  constructor(prefix: string = '') {
    this.prefix = prefix;
  }

  private formatMessage(...args: any[]): string {
    const timestamp = new Date().toISOString();
    const prefixStr = this.prefix ? `[${this.prefix}] ` : '';
    return `${timestamp} ${prefixStr}${args.join(' ')}`;
  }

  info(...args: any[]): void {
    console.log('[INFO]', this.formatMessage(...args));
  }

  error(...args: any[]): void {
    console.error('[ERROR]', this.formatMessage(...args));
  }

  warn(...args: any[]): void {
    console.warn('[WARN]', this.formatMessage(...args));
  }

  debug(...args: any[]): void {
    if (process.env.DEBUG) {
      console.log('[DEBUG]', this.formatMessage(...args));
    }
  }
}

// Default logger instance
const logger = new Logger();

// Helper functions for structured logging
export function logApiCall(
  service: string,
  method: string,
  duration: number,
  success: boolean,
  metadata?: Record<string, any>
): void {
  const message = `[API] ${service}.${method} - ${success ? 'SUCCESS' : 'FAILED'} (${duration}ms)`;
  if (success) {
    logger.info(message, metadata || {});
  } else {
    logger.error(message, metadata || {});
  }
}

export function logGeneration(
  type: string,
  duration: number,
  itemsGenerated: number,
  metadata?: Record<string, any>
): void {
  const message = `[GENERATION] ${type} - Generated ${itemsGenerated} items in ${duration}ms`;
  logger.info(message, metadata || {});
}

export function logRateLimit(
  service: string,
  limit: number,
  remaining: number,
  resetAt?: Date
): void {
  const message = `[RATE_LIMIT] ${service} - ${remaining}/${limit} remaining`;
  logger.warn(message, { service, limit, remaining, resetAt });
}

export default logger;
export { Logger };
