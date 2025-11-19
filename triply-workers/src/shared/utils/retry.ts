/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Retry Utility with Exponential Backoff
 * Для надёжных вызовов внешних API
 * ═══════════════════════════════════════════════════════════════════════════
 */

import config from '../config/env.js';
import logger from './logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

export interface RetryOptions {
  maxRetries?: number;
  initialDelay?: number;
  backoffMultiplier?: number;
  maxDelay?: number;
  shouldRetry?: (error: any) => boolean;
  onRetry?: (attempt: number, error: any) => void;
}

// ═══════════════════════════════════════════════════════════════════════════
// Default Options
// ═══════════════════════════════════════════════════════════════════════════

const defaultOptions: Required<Omit<RetryOptions, 'onRetry'>> = {
  maxRetries: config.MAX_RETRIES,
  initialDelay: config.RETRY_DELAY_MS,
  backoffMultiplier: config.RETRY_BACKOFF_MULTIPLIER,
  maxDelay: 30000, // 30 seconds max
  shouldRetry: (error: any) => {
    // Retry on network errors and 5xx status codes
    if (error.code === 'ECONNRESET' || error.code === 'ETIMEDOUT') return true;
    if (error.response?.status >= 500 && error.response?.status < 600)
      return true;
    if (error.response?.status === 429) return true; // Rate limit
    return false;
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// Retry Function
// ═══════════════════════════════════════════════════════════════════════════

export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const opts = { ...defaultOptions, ...options };
  let lastError: any;

  for (let attempt = 0; attempt <= opts.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Check if should retry
      if (attempt === opts.maxRetries || !opts.shouldRetry(error)) {
        throw error;
      }

      // Calculate delay with exponential backoff
      const delay = Math.min(
        opts.initialDelay * Math.pow(opts.backoffMultiplier, attempt),
        opts.maxDelay
      );

      logger.warn(
        `Retrying after ${delay}ms (attempt ${attempt + 1}/${opts.maxRetries}): ${error.message}`
      );

      // Call onRetry callback
      if (options.onRetry) {
        options.onRetry(attempt + 1, error);
      }

      // Wait before retry
      await sleep(delay);
    }
  }

  throw lastError;
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper: Sleep
// ═══════════════════════════════════════════════════════════════════════════

const sleep = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

// ═══════════════════════════════════════════════════════════════════════════
// Circuit Breaker State
// ═══════════════════════════════════════════════════════════════════════════

class CircuitBreaker {
  private failures = 0;
  private lastFailureTime: number | null = null;
  private state: 'closed' | 'open' | 'half-open' = 'closed';

  constructor(
    private threshold: number = config.CIRCUIT_BREAKER_THRESHOLD,
    private timeout: number = config.CIRCUIT_BREAKER_TIMEOUT_MS
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      const now = Date.now();
      if (this.lastFailureTime && now - this.lastFailureTime >= this.timeout) {
        this.state = 'half-open';
        logger.info('Circuit breaker: transitioning to half-open');
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    if (this.state === 'half-open') {
      logger.info('Circuit breaker: transitioning to closed');
    }
    this.failures = 0;
    this.state = 'closed';
  }

  private onFailure() {
    this.failures++;
    this.lastFailureTime = Date.now();

    if (this.failures >= this.threshold) {
      this.state = 'open';
      logger.error(`Circuit breaker: OPEN (failures: ${this.failures})`);
    }
  }

  getState() {
    return {
      state: this.state,
      failures: this.failures,
      lastFailureTime: this.lastFailureTime,
    };
  }

  reset() {
    this.failures = 0;
    this.lastFailureTime = null;
    this.state = 'closed';
    logger.info('Circuit breaker: manually reset');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Export Circuit Breaker instances for different services
// ═══════════════════════════════════════════════════════════════════════════

export const circuitBreakers = {
  openai: new CircuitBreaker(),
  googlePlaces: new CircuitBreaker(),
  unsplash: new CircuitBreaker(),
  pexels: new CircuitBreaker(),
  supabase: new CircuitBreaker(),
};

export default retry;
