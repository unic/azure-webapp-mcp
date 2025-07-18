# Start with a base Python image
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# Copy UV tools from the Astral repository
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory
WORKDIR /app

# Mount the necessary cache and bind the pyproject.toml and uv.lock
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project

# Copy the application code into the container
ADD . /app

# Sync project dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen

# Expose the application port
EXPOSE 8000

# Set the command to run with uvicorn through uv
CMD ["uv", "run", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]