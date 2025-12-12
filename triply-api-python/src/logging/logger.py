"""
Structured logging configuration for Triply API
"""

import sys
import uuid
import logging
from datetime import datetime
from typing import Any
from contextvars import ContextVar
from functools import wraps
import time

import structlog
from structlog.typing import Processor

from ..config import settings


# Context variable for request-scoped data
_request_context: ContextVar[dict] = ContextVar("request_context", default={})


class LogContext:
    """Context manager for adding contextual data to logs"""

    def __init__(self, **kwargs):
        self.data = kwargs
        self.token = None

    def __enter__(self):
        current = _request_context.get()
        self.token = _request_context.set({**current, **self.data})
        return self

    def __exit__(self, *args):
        if self.token:
            _request_context.reset(self.token)


def request_context(**kwargs):
    """Decorator to add context to a function's logs"""
    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kw):
            with LogContext(**kwargs):
                return await func(*args, **kw)

        @wraps(func)
        def sync_wrapper(*args, **kw):
            with LogContext(**kwargs):
                return func(*args, **kw)

        if asyncio_iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper
    return decorator


def asyncio_iscoroutinefunction(func):
    """Check if function is async"""
    import asyncio
    return asyncio.iscoroutinefunction(func)


def add_request_context(logger, method_name, event_dict):
    """Processor to add request context to log entries"""
    ctx = _request_context.get()
    if ctx:
        event_dict.update(ctx)
    return event_dict


def add_service_info(logger, method_name, event_dict):
    """Add service metadata to all logs"""
    event_dict["service"] = "triply-api"
    event_dict["version"] = "2.0.0"
    event_dict["env"] = settings.env
    return event_dict


def format_timestamp(logger, method_name, event_dict):
    """Add ISO formatted timestamp"""
    event_dict["timestamp"] = datetime.utcnow().isoformat() + "Z"
    return event_dict


def setup_logging():
    """Configure structured logging for the application"""

    # Determine log level from settings
    log_level = logging.DEBUG if settings.is_dev else logging.INFO

    # Shared processors
    shared_processors: list[Processor] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        add_service_info,
        add_request_context,
        format_timestamp,
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]

    if settings.is_prod:
        # Production: JSON output for log aggregation
        processors = shared_processors + [
            structlog.processors.JSONRenderer()
        ]
    else:
        # Development: Pretty console output
        processors = shared_processors + [
            structlog.dev.ConsoleRenderer(
                colors=True,
                exception_formatter=structlog.dev.plain_traceback,
            )
        ]

    structlog.configure(
        processors=processors,
        wrapper_class=structlog.make_filtering_bound_logger(log_level),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # Also configure standard library logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=log_level,
    )

    # Reduce noise from third-party libraries
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)


def get_logger(name: str = None) -> structlog.BoundLogger:
    """Get a structured logger instance"""
    return structlog.get_logger(name or "triply")


# Specialized loggers
class AgentLogger:
    """Logger specifically for agent operations"""

    def __init__(self, trip_id: str = None, query: str = None):
        self.logger = get_logger("agent")
        self.trip_id = trip_id
        self.query = query
        self.start_time = None
        self.step_count = 0

    def _base_context(self) -> dict:
        ctx = {"component": "agent"}
        if self.trip_id:
            ctx["trip_id"] = self.trip_id
        if self.query:
            ctx["query"] = self.query[:100]  # Truncate long queries
        return ctx

    def start(self, query: str):
        """Log agent execution start"""
        self.query = query
        self.start_time = time.time()
        self.step_count = 0
        self.logger.info(
            "agent_start",
            **self._base_context(),
            query_length=len(query),
        )

    def step(self, step_type: str, details: dict = None):
        """Log an agent step (thinking, tool use, etc.)"""
        self.step_count += 1
        elapsed = time.time() - self.start_time if self.start_time else 0
        self.logger.info(
            "agent_step",
            **self._base_context(),
            step_type=step_type,
            step_number=self.step_count,
            elapsed_seconds=round(elapsed, 2),
            **(details or {}),
        )

    def tool_call(self, tool_name: str, args: dict = None, result_summary: str = None):
        """Log a tool invocation"""
        self.step_count += 1
        elapsed = time.time() - self.start_time if self.start_time else 0
        self.logger.info(
            "agent_tool_call",
            **self._base_context(),
            tool_name=tool_name,
            step_number=self.step_count,
            elapsed_seconds=round(elapsed, 2),
            args_preview=str(args)[:200] if args else None,
            result_preview=result_summary[:200] if result_summary else None,
        )

    def complete(self, success: bool, response_length: int = 0, error: str = None):
        """Log agent execution completion"""
        elapsed = time.time() - self.start_time if self.start_time else 0
        log_data = {
            **self._base_context(),
            "success": success,
            "total_steps": self.step_count,
            "duration_seconds": round(elapsed, 2),
            "response_length": response_length,
        }
        if error:
            log_data["error"] = error
            self.logger.error("agent_complete", **log_data)
        else:
            self.logger.info("agent_complete", **log_data)


class SSELogger:
    """Logger for SSE streaming events"""

    def __init__(self, trip_id: str):
        self.logger = get_logger("sse")
        self.trip_id = trip_id
        self.event_count = 0
        self.start_time = time.time()

    def _base_context(self) -> dict:
        return {
            "component": "sse",
            "trip_id": self.trip_id,
        }

    def event(self, event_type: str, data_preview: str = None):
        """Log an SSE event being sent"""
        self.event_count += 1
        elapsed = time.time() - self.start_time
        self.logger.debug(
            "sse_event",
            **self._base_context(),
            event_type=event_type,
            event_number=self.event_count,
            elapsed_seconds=round(elapsed, 2),
            data_preview=data_preview[:100] if data_preview else None,
        )

    def stream_start(self):
        """Log SSE stream start"""
        self.logger.info(
            "sse_stream_start",
            **self._base_context(),
        )

    def stream_end(self, success: bool = True, error: str = None):
        """Log SSE stream end"""
        elapsed = time.time() - self.start_time
        log_data = {
            **self._base_context(),
            "total_events": self.event_count,
            "duration_seconds": round(elapsed, 2),
            "success": success,
        }
        if error:
            log_data["error"] = error
            self.logger.error("sse_stream_end", **log_data)
        else:
            self.logger.info("sse_stream_end", **log_data)


class RequestLogger:
    """Logger for HTTP requests"""

    def __init__(self):
        self.logger = get_logger("http")

    def request(
        self,
        request_id: str,
        method: str,
        path: str,
        client_ip: str = None,
        user_agent: str = None,
    ):
        """Log incoming request"""
        self.logger.info(
            "http_request",
            component="http",
            request_id=request_id,
            method=method,
            path=path,
            client_ip=client_ip,
            user_agent=user_agent[:100] if user_agent else None,
        )

    def response(
        self,
        request_id: str,
        method: str,
        path: str,
        status_code: int,
        duration_ms: float,
    ):
        """Log response"""
        level = "info" if status_code < 400 else "warning" if status_code < 500 else "error"
        log_method = getattr(self.logger, level)
        log_method(
            "http_response",
            component="http",
            request_id=request_id,
            method=method,
            path=path,
            status_code=status_code,
            duration_ms=round(duration_ms, 2),
        )
