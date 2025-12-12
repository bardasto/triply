"""
HTTP Request/Response Logging Middleware
"""

import time
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from .logger import RequestLogger, LogContext


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware that logs all HTTP requests and responses"""

    # Paths to skip logging (health checks, static files, etc.)
    SKIP_PATHS = {"/", "/health", "/favicon.ico"}

    def __init__(self, app):
        super().__init__(app)
        self.request_logger = RequestLogger()

    async def dispatch(self, request: Request, call_next) -> Response:
        # Generate unique request ID
        request_id = str(uuid.uuid4())[:8]

        # Skip logging for health checks
        if request.url.path in self.SKIP_PATHS:
            return await call_next(request)

        # Extract request info
        method = request.method
        path = request.url.path
        client_ip = self._get_client_ip(request)
        user_agent = request.headers.get("user-agent")

        # Log incoming request
        self.request_logger.request(
            request_id=request_id,
            method=method,
            path=path,
            client_ip=client_ip,
            user_agent=user_agent,
        )

        # Add request context for all downstream logs
        start_time = time.time()

        with LogContext(request_id=request_id, path=path, method=method):
            try:
                response = await call_next(request)

                # Calculate duration
                duration_ms = (time.time() - start_time) * 1000

                # Log response
                self.request_logger.response(
                    request_id=request_id,
                    method=method,
                    path=path,
                    status_code=response.status_code,
                    duration_ms=duration_ms,
                )

                # Add request ID to response headers
                response.headers["X-Request-ID"] = request_id

                return response

            except Exception as e:
                duration_ms = (time.time() - start_time) * 1000
                self.request_logger.response(
                    request_id=request_id,
                    method=method,
                    path=path,
                    status_code=500,
                    duration_ms=duration_ms,
                )
                raise

    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP, handling proxies"""
        # Check X-Forwarded-For header (set by proxies/load balancers)
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            # Take the first IP in the chain
            return forwarded_for.split(",")[0].strip()

        # Check X-Real-IP header
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip

        # Fall back to direct client IP
        if request.client:
            return request.client.host

        return "unknown"
