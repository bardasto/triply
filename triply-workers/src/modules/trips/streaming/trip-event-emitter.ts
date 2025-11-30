/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Trip Event Emitter
 * Manages event distribution for streaming trip generation
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { EventEmitter } from 'events';
import type {
  TripEvent,
  TripEventType,
  GenerationState,
  GenerationPhase,
  SkeletonEvent,
  DayEvent,
  PlaceEvent,
  ImageEvent,
  PricesEvent,
  CompleteEvent,
  ErrorEvent,
  InitEvent,
} from './types.js';
import logger from '../../../shared/utils/logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Trip Event Emitter Class
// ═══════════════════════════════════════════════════════════════════════════

export class TripEventEmitter extends EventEmitter {
  private tripId: string;
  private state: GenerationState;
  private sequenceCounter: number = 0;
  private startTime: number;

  constructor(tripId: string) {
    super();
    this.tripId = tripId;
    this.startTime = Date.now();
    this.state = {
      tripId,
      phase: 'initializing',
      progress: 0,
      startTime: this.startTime,
      skeleton: null,
      days: new Map(),
      places: new Map(),
      images: new Map(),
      errors: [],
    };

    // Set max listeners to avoid warnings for multiple SSE clients
    this.setMaxListeners(50);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // State Management
  // ═══════════════════════════════════════════════════════════════════════════

  getState(): GenerationState {
    return { ...this.state };
  }

  setPhase(phase: GenerationPhase, progress?: number): void {
    this.state.phase = phase;
    if (progress !== undefined) {
      this.state.progress = progress;
    }
    logger.info(`[${this.tripId}] Phase: ${phase} (${this.state.progress}%)`);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Event Emission Methods
  // ═══════════════════════════════════════════════════════════════════════════

  private createBaseEvent(type: TripEventType): Omit<TripEvent, 'data'> {
    return {
      type,
      tripId: this.tripId,
      timestamp: Date.now(),
      sequence: ++this.sequenceCounter,
    };
  }

  emitInit(): void {
    this.setPhase('initializing', 0);
    const event: InitEvent = {
      ...this.createBaseEvent('init'),
      type: 'init',
      data: {
        status: 'generating',
        estimatedDuration: 10, // seconds
      },
    };
    this.emit('event', event);
    logger.info(`[${this.tripId}] 🚀 Trip generation started`);
  }

  emitSkeleton(data: SkeletonEvent['data']): void {
    this.setPhase('generating_skeleton', 15);
    this.state.skeleton = data;
    const event: SkeletonEvent = {
      ...this.createBaseEvent('skeleton'),
      type: 'skeleton',
      data,
    };
    this.emit('event', event);
    logger.info(`[${this.tripId}] 📋 Skeleton: "${data.title}"`);
  }

  emitDay(data: DayEvent['data']): void {
    const progress = 20 + (data.day * 10);
    this.setPhase('generating_skeleton', Math.min(progress, 50));
    this.state.days.set(data.day, data);
    const event: DayEvent = {
      ...this.createBaseEvent('day'),
      type: 'day',
      data,
    };
    this.emit('event', event);
    logger.info(`[${this.tripId}] 📅 Day ${data.day}: "${data.title}"`);
  }

  emitPlace(data: PlaceEvent['data']): void {
    this.setPhase('assigning_places', 60);
    const key = `${data.day}-${data.slot}-${data.index}`;
    this.state.places.set(key, data);
    const event: PlaceEvent = {
      ...this.createBaseEvent('place'),
      type: 'place',
      data,
    };
    this.emit('event', event);
    logger.info(`[${this.tripId}] 📍 Place: "${data.place.name}" (Day ${data.day}, ${data.slot})`);
  }

  emitImage(data: ImageEvent['data']): void {
    this.setPhase('loading_images', 80);
    const key = data.placeId || data.imageType;
    this.state.images.set(key, data);
    const event: ImageEvent = {
      ...this.createBaseEvent('image'),
      type: 'image',
      data,
    };
    this.emit('event', event);
    logger.debug(`[${this.tripId}] 🖼️ Image: ${data.imageType} ${data.placeName || ''}`);
  }

  emitPrices(data: PricesEvent['data']): void {
    this.setPhase('finalizing', 90);
    const event: PricesEvent = {
      ...this.createBaseEvent('prices'),
      type: 'prices',
      data,
    };
    this.emit('event', event);
    logger.info(`[${this.tripId}] 💰 Prices: €${data.totalMin}-${data.totalMax}`);
  }

  emitComplete(): void {
    this.setPhase('complete', 100);
    const generationTimeMs = Date.now() - this.startTime;
    const event: CompleteEvent = {
      ...this.createBaseEvent('complete'),
      type: 'complete',
      data: {
        tripId: this.tripId,
        generatedAt: new Date().toISOString(),
        generationTimeMs,
        totalPlaces: this.state.places.size,
        totalImages: this.state.images.size,
      },
    };
    this.emit('event', event);
    logger.info(`[${this.tripId}] ✅ Complete in ${(generationTimeMs / 1000).toFixed(1)}s`);

    // Clean up after a short delay
    setTimeout(() => this.cleanup(), 5000);
  }

  emitError(code: string, message: string, phase: string, recoverable: boolean = false): void {
    this.setPhase('error', this.state.progress);
    const errorData = { code, message, recoverable, phase };
    this.state.errors.push(errorData);
    const event: ErrorEvent = {
      ...this.createBaseEvent('error'),
      type: 'error',
      data: errorData,
    };
    this.emit('event', event);
    logger.error(`[${this.tripId}] ❌ Error in ${phase}: ${message}`);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility Methods
  // ═══════════════════════════════════════════════════════════════════════════

  getElapsedTime(): number {
    return Date.now() - this.startTime;
  }

  getTripId(): string {
    return this.tripId;
  }

  cleanup(): void {
    this.removeAllListeners();
    logger.debug(`[${this.tripId}] Cleaned up event emitter`);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Trip Event Manager (Singleton)
// Manages all active trip generations
// ═══════════════════════════════════════════════════════════════════════════

class TripEventManager {
  private activeTrips: Map<string, TripEventEmitter> = new Map();
  private static instance: TripEventManager;

  private constructor() {
    logger.info('✅ Trip Event Manager initialized');
  }

  static getInstance(): TripEventManager {
    if (!TripEventManager.instance) {
      TripEventManager.instance = new TripEventManager();
    }
    return TripEventManager.instance;
  }

  createEmitter(tripId: string): TripEventEmitter {
    // Clean up existing emitter if any
    if (this.activeTrips.has(tripId)) {
      this.activeTrips.get(tripId)?.cleanup();
    }

    const emitter = new TripEventEmitter(tripId);
    this.activeTrips.set(tripId, emitter);

    // Auto-cleanup after 5 minutes (safety net)
    setTimeout(() => {
      if (this.activeTrips.has(tripId)) {
        this.removeEmitter(tripId);
      }
    }, 5 * 60 * 1000);

    return emitter;
  }

  getEmitter(tripId: string): TripEventEmitter | undefined {
    return this.activeTrips.get(tripId);
  }

  removeEmitter(tripId: string): void {
    const emitter = this.activeTrips.get(tripId);
    if (emitter) {
      emitter.cleanup();
      this.activeTrips.delete(tripId);
      logger.debug(`Removed emitter for trip ${tripId}`);
    }
  }

  getActiveTripsCount(): number {
    return this.activeTrips.size;
  }
}

export const tripEventManager = TripEventManager.getInstance();
