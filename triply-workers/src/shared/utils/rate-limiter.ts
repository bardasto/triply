/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Rate Limiter
 * Token Bucket алгоритм для защиты от превышения лимитов API
 * ═══════════════════════════════════════════════════════════════════════════
 */

import config from '../config/env.js';
import logger, { logRateLimit } from './logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Token Bucket Rate Limiter
// ═══════════════════════════════════════════════════════════════════════════

class TokenBucketRateLimiter {
  private tokens: number;
  private lastRefillTime: number;

  constructor(
    private maxTokens: number, // Максимум токенов (requests per minute)
    private refillRate: number = maxTokens / 60 // Токенов в секунду
  ) {
    this.tokens = maxTokens;
    this.lastRefillTime = Date.now();
  }

  /**
   * Попытка получить токен (разрешение на запрос)
   * Возвращает true если токен доступен, false если лимит превышен
   */
  async acquire(cost: number = 1): Promise<boolean> {
    this.refill();

    if (this.tokens >= cost) {
      this.tokens -= cost;
      return true;
    }

    return false;
  }

  /**
   * Ожидание до получения токена
   * Блокирует выполнение пока не появится доступный токен
   */
  async acquireBlocking(cost: number = 1): Promise<void> {
    while (true) {
      if (await this.acquire(cost)) {
        return;
      }

      // Подождать до следующего refill
      const waitTime = this.getWaitTime(cost);
      if (waitTime > 0) {
        await this.sleep(waitTime);
      }
    }
  }

  /**
   * Пополнить токены на основе времени
   */
  private refill(): void {
    const now = Date.now();
    const timePassed = (now - this.lastRefillTime) / 1000; // секунды
    const tokensToAdd = timePassed * this.refillRate;

    if (tokensToAdd > 0) {
      this.tokens = Math.min(this.maxTokens, this.tokens + tokensToAdd);
      this.lastRefillTime = now;
    }
  }

  /**
   * Получить время ожидания в миллисекундах
   */
  private getWaitTime(cost: number): number {
    const tokensNeeded = Math.max(0, cost - this.tokens);
    return (tokensNeeded / this.refillRate) * 1000;
  }

  /**
   * Получить текущее состояние
   */
  getStatus() {
    this.refill();
    return {
      tokens: Math.floor(this.tokens),
      maxTokens: this.maxTokens,
      percentage: (this.tokens / this.maxTokens) * 100,
    };
  }

  /**
   * Sleep helper
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Reset limiter
   */
  reset(): void {
    this.tokens = this.maxTokens;
    this.lastRefillTime = Date.now();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sliding Window Rate Limiter (альтернативный подход)
// ═══════════════════════════════════════════════════════════════════════════

class SlidingWindowRateLimiter {
  private requests: number[] = [];

  constructor(
    private maxRequests: number,
    private windowMs: number = 60000 // 1 минута
  ) {}

  async acquire(): Promise<boolean> {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    // Удалить старые запросы
    this.requests = this.requests.filter(time => time > windowStart);

    if (this.requests.length < this.maxRequests) {
      this.requests.push(now);
      return true;
    }

    return false;
  }

  async acquireBlocking(): Promise<void> {
    while (!(await this.acquire())) {
      const oldestRequest = this.requests[0];
      const waitTime = oldestRequest + this.windowMs - Date.now();
      if (waitTime > 0) {
        await this.sleep(Math.min(waitTime, 1000));
      }
    }
  }

  getStatus() {
    const now = Date.now();
    const windowStart = now - this.windowMs;
    this.requests = this.requests.filter(time => time > windowStart);

    return {
      requests: this.requests.length,
      maxRequests: this.maxRequests,
      percentage: (this.requests.length / this.maxRequests) * 100,
      nextReset: this.requests[0] ? this.requests[0] + this.windowMs : now,
    };
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  reset(): void {
    this.requests = [];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Rate Limiter Manager - создаёт и управляет лимитерами для разных сервисов
// ═══════════════════════════════════════════════════════════════════════════

class RateLimiterManager {
  private limiters: Map<string, TokenBucketRateLimiter> = new Map();

  /**
   * Получить или создать лимитер для сервиса
   */
  getLimiter(service: string, maxRequests?: number): TokenBucketRateLimiter {
    if (!this.limiters.has(service)) {
      const limit = maxRequests || this.getDefaultLimit(service);
      this.limiters.set(service, new TokenBucketRateLimiter(limit));
      logger.info(`Rate limiter created for ${service}: ${limit} req/min`);
    }
    return this.limiters.get(service)!;
  }

  /**
   * Получить лимит по умолчанию для сервиса
   */
  private getDefaultLimit(service: string): number {
    const limits: Record<string, number> = {
      openai: config.RATE_LIMIT_OPENAI,
      gemini: config.RATE_LIMIT_GEMINI,
      google_places: config.RATE_LIMIT_GOOGLE_PLACES,
      unsplash: config.RATE_LIMIT_UNSPLASH,
      pexels: config.RATE_LIMIT_PEXELS,
    };
    return limits[service] || 100;
  }

  /**
   * Выполнить запрос с rate limiting
   */
  async execute<T>(
    service: string,
    fn: () => Promise<T>,
    options?: {
      cost?: number;
      blocking?: boolean;
    }
  ): Promise<T> {
    // Пропустить лимиты если включен SKIP_RATE_LIMITS
    if (config.SKIP_RATE_LIMITS) {
      return await fn();
    }

    const limiter = this.getLimiter(service);
    const cost = options?.cost || 1;
    const blocking = options?.blocking !== false; // default true

    if (blocking) {
      await limiter.acquireBlocking(cost);
    } else {
      const acquired = await limiter.acquire(cost);
      if (!acquired) {
        const status = limiter.getStatus();
        logRateLimit(service, status.maxTokens, status.tokens);
        throw new Error(`Rate limit exceeded for ${service}`);
      }
    }

    return await fn();
  }

  /**
   * Получить статус всех лимитеров
   */
  getStatus(): Record<string, any> {
    const status: Record<string, any> = {};
    this.limiters.forEach((limiter, service) => {
      status[service] = limiter.getStatus();
    });
    return status;
  }

  /**
   * Сбросить все лимитеры
   */
  resetAll(): void {
    this.limiters.forEach(limiter => limiter.reset());
    logger.info('All rate limiters reset');
  }

  /**
   * Сбросить лимитер конкретного сервиса
   */
  reset(service: string): void {
    const limiter = this.limiters.get(service);
    if (limiter) {
      limiter.reset();
      logger.info(`Rate limiter reset for ${service}`);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const rateLimiterManager = new RateLimiterManager();

// ═══════════════════════════════════════════════════════════════════════════
// Export
// ═══════════════════════════════════════════════════════════════════════════

export {
  TokenBucketRateLimiter,
  SlidingWindowRateLimiter,
  RateLimiterManager,
  rateLimiterManager,
};

export default rateLimiterManager;
