
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.concurrency import iterate_in_threadpool
from starlette.middleware import Middleware
import json
import re
import logging

def set_id_and_rechunk_response(response_data_chunks: list[bytes]) -> list[bytes]:
    if not response_data_chunks:
        return []
    full_response_str = b"".join(response_data_chunks).decode("utf-8")
    match = re.search(r"data:\s*({.*})", full_response_str, re.DOTALL)
    if not match:
        return response_data_chunks
    json_str = match.group(1)
    try:
        data_payload = json.loads(json_str)
        if "id" in data_payload:
            data_payload["id"] = str(data_payload["id"])
        modified_json_str = json.dumps(data_payload, separators=(",", ":"))
        modified_full_response_str = full_response_str.replace(json_str, modified_json_str)
        modified_response_bytes = modified_full_response_str.encode("utf-8")
    except json.JSONDecodeError:
        return response_data_chunks
    total_original_size = sum(len(c) for c in response_data_chunks)
    num_original_chunks = len(response_data_chunks)
    avg_chunk_size = (
        (total_original_size // num_original_chunks) if num_original_chunks > 0 else 4096
    )
    if avg_chunk_size == 0:
        avg_chunk_size = 4096
    new_chunks = []
    for i in range(0, len(modified_response_bytes), avg_chunk_size):
        chunk = modified_response_bytes[i : i + avg_chunk_size]
        new_chunks.append(chunk)
    return new_chunks

class IDTypeMismatchFixMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp):
        super().__init__(app)

    async def dispatch(self, request, call_next):
        request_body = b""
        response_body_chunks = []
        async for chunk in request.stream():
            request_body += chunk
        request._body = request_body
        is_request_id_str = False
        if request_body:
            json_request_body = json.loads(request_body)
            is_request_id_str = "id" in json_request_body and isinstance(
                json_request_body["id"], str
            )
        response = await call_next(request)
        from starlette.middleware.base import _StreamingResponse
        if isinstance(response, _StreamingResponse):
            async for chunk in response.body_iterator:
                response_body_chunks.append(chunk)
            if is_request_id_str:
                response_body_chunks = set_id_and_rechunk_response(response_body_chunks)
            response.body_iterator = iterate_in_threadpool(iter(response_body_chunks))
        return response

class ExceptionMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp):
        super().__init__(app)

    async def dispatch(self, request, call_next):
        try:
            response = await call_next(request)
        except RequestValidationError as exc:
            logging.exception("Request validation error", exc_info=exc)
            response = JSONResponse(
                status_code=422,
                content={"detail": exc.errors(), "body": exc.body},
            )
        except StarletteHTTPException as exc:
            logging.exception("Starlette HTTP exception", exc_info=exc)
            response = JSONResponse(
                status_code=exc.status_code or 503, content={"detail": str(exc.detail)}
            )
        except Exception as exc:
            logging.exception("Unhandled exception", exc_info=exc)
            response = JSONResponse(
                content={"message": "Unhandled exception encountered"}, status_code=500
            )
        return response

custom_middleware = [
    Middleware(IDTypeMismatchFixMiddleware),
    Middleware(ExceptionMiddleware),
]
