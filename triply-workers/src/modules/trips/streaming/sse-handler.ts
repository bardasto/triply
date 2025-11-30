/**
 * ═══════════════════════════════════════════════════════════════════════════
 * SSE (Server-Sent Events) Handler
 * Manages SSE connections for real-time trip streaming
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import type { TripEvent, SSEClient } from './types.js';
import { TripEventEmitter, tripEventManager } from './trip-event-emitter.js';
import tripOrchestrator from './trip-orchestrator.js';
import logger from '../../../shared/utils/logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// SSE Connection Manager
// ═══════════════════════════════════════════════════════════════════════════

class SSEConnectionManager {
  private clients: Map<string, SSEClient[]> = new Map(); // tripId -> clients
  private static instance: SSEConnectionManager;

  private constructor() {
    logger.info('✅ SSE Connection Manager initialized');
  }

  static getInstance(): SSEConnectionManager {
    if (!SSEConnectionManager.instance) {
      SSEConnectionManager.instance = new SSEConnectionManager();
    }
    return SSEConnectionManager.instance;
  }

  /**
   * Add a new SSE client for a trip
   */
  addClient(tripId: string, response: Response): SSEClient {
    const client: SSEClient = {
      id: uuidv4(),
      tripId,
      response,
      connected: true,
      connectedAt: Date.now(),
    };

    if (!this.clients.has(tripId)) {
      this.clients.set(tripId, []);
    }
    this.clients.get(tripId)!.push(client);

    logger.info(`[SSE] Client ${client.id} connected for trip ${tripId}`);
    return client;
  }

  /**
   * Remove a client
   */
  removeClient(clientId: string): void {
    for (const [tripId, clients] of this.clients.entries()) {
      const index = clients.findIndex(c => c.id === clientId);
      if (index !== -1) {
        clients[index].connected = false;
        clients.splice(index, 1);
        logger.info(`[SSE] Client ${clientId} disconnected from trip ${tripId}`);

        // Clean up empty trip entries
        if (clients.length === 0) {
          this.clients.delete(tripId);
        }
        return;
      }
    }
  }

  /**
   * Send event to all clients for a trip
   */
  sendEvent(tripId: string, event: TripEvent): void {
    const clients = this.clients.get(tripId);
    if (!clients || clients.length === 0) return;

    const message = this.formatSSEMessage(event);

    for (const client of clients) {
      if (client.connected) {
        try {
          client.response.write(message);
        } catch (error) {
          logger.warn(`[SSE] Failed to send to client ${client.id}:`, error);
          client.connected = false;
        }
      }
    }
  }

  /**
   * Format event as SSE message
   */
  private formatSSEMessage(event: TripEvent): string {
    const eventType = event.type;
    const data = JSON.stringify(event);
    const id = `${event.tripId}-${event.sequence}`;

    return `event: ${eventType}\nid: ${id}\ndata: ${data}\n\n`;
  }

  /**
   * Get client count for a trip
   */
  getClientCount(tripId: string): number {
    return this.clients.get(tripId)?.length || 0;
  }
}

export const sseConnectionManager = SSEConnectionManager.getInstance();

// ═══════════════════════════════════════════════════════════════════════════
// SSE Request Handlers
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Handle POST request to start trip generation
 * Returns tripId for SSE connection
 */
export async function handleStartGeneration(req: Request, res: Response): Promise<void> {
  try {
    const { query, conversationContext } = req.body;

    if (!query) {
      res.status(400).json({
        success: false,
        error: { code: 'MISSING_QUERY', message: 'Query is required' },
      });
      return;
    }

    const tripId = uuidv4();

    logger.info(`[${tripId}] Starting streaming trip generation`);
    logger.info(`[${tripId}] Query: "${query}"`);

    // Start generation (non-blocking)
    const emitter = await tripOrchestrator.generateTrip({
      tripId,
      userQuery: query,
      conversationContext,
    });

    // Wire up emitter to SSE
    emitter.on('event', (event: TripEvent) => {
      sseConnectionManager.sendEvent(tripId, event);
    });

    // Return tripId immediately
    res.json({
      success: true,
      data: {
        tripId,
        streamUrl: `/api/trips/stream/${tripId}`,
        status: 'generating',
      },
    });

  } catch (error: any) {
    logger.error('Failed to start generation:', error);
    res.status(500).json({
      success: false,
      error: { code: 'START_FAILED', message: error.message },
    });
  }
}

/**
 * Handle SSE connection for streaming trip events
 */
export function handleSSEConnection(req: Request, res: Response): void {
  const tripId = req.params.tripId;

  if (!tripId) {
    res.status(400).json({
      success: false,
      error: { code: 'MISSING_TRIP_ID', message: 'Trip ID is required' },
    });
    return;
  }

  logger.info(`[${tripId}] New SSE connection request`);

  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no'); // Disable nginx buffering
  res.setHeader('Access-Control-Allow-Origin', '*');

  // Disable response timeout
  req.socket.setTimeout(0);

  // Send initial connection event
  res.write(`event: connected\ndata: {"tripId":"${tripId}","timestamp":${Date.now()}}\n\n`);

  // Register client
  const client = sseConnectionManager.addClient(tripId, res);

  // Check if generation already exists
  const emitter = tripEventManager.getEmitter(tripId);
  if (emitter) {
    // Send current state to catch up
    const state = emitter.getState();

    if (state.skeleton) {
      const skeletonEvent: TripEvent = {
        type: 'skeleton',
        tripId,
        timestamp: Date.now(),
        sequence: 0,
        data: state.skeleton,
      };
      res.write(sseConnectionManager['formatSSEMessage'](skeletonEvent));
    }

    // Send existing days
    for (const [dayNum, dayData] of state.days) {
      const dayEvent: TripEvent = {
        type: 'day',
        tripId,
        timestamp: Date.now(),
        sequence: 0,
        data: dayData,
      };
      res.write(sseConnectionManager['formatSSEMessage'](dayEvent));
    }

    // Send existing places
    for (const [key, placeData] of state.places) {
      const placeEvent: TripEvent = {
        type: 'place',
        tripId,
        timestamp: Date.now(),
        sequence: 0,
        data: placeData,
      };
      res.write(sseConnectionManager['formatSSEMessage'](placeEvent));
    }

    // If already complete, send complete event
    if (state.phase === 'complete') {
      res.write(`event: complete\ndata: {"tripId":"${tripId}","status":"complete"}\n\n`);
    }
  }

  // Handle client disconnect
  req.on('close', () => {
    sseConnectionManager.removeClient(client.id);
    logger.info(`[${tripId}] SSE connection closed`);
  });

  // Keep connection alive with heartbeat
  const heartbeat = setInterval(() => {
    if (client.connected) {
      try {
        res.write(`:heartbeat ${Date.now()}\n\n`);
      } catch (error) {
        clearInterval(heartbeat);
      }
    } else {
      clearInterval(heartbeat);
    }
  }, 30000); // Every 30 seconds

  // Clean up on close
  res.on('close', () => {
    clearInterval(heartbeat);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Export type (re-exported from types.ts)
// ═══════════════════════════════════════════════════════════════════════════

export type { TripEvent } from './types.js';
