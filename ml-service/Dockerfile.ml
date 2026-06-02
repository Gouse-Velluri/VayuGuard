FROM python:3.11-slim

LABEL maintainer="VayuGuard Team"
LABEL description="VayuGuard ML Service - AQI Forecasting API"
LABEL version="1.0.0"

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install PyTorch (CPU-only for smaller image)
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/data /app/cache /app/artifacts /app/logs

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
ENV ARTIFACT_DIR=/app/artifacts
ENV CORS_ORIGINS=*
ENV LOG_LEVEL=INFO

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Run the FastAPI application
CMD ["uvicorn", "inference.fastapi_app:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "4", \
     "--log-level", "info", \
     "--access-log"]
