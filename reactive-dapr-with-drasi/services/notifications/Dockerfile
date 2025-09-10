# Build stage for UI
FROM node:20-alpine as ui-builder

WORKDIR /app/ui

# Copy UI package files
COPY ui/package*.json ./
RUN npm install

# Copy UI source code
COPY ui/ .

# Build the UI
RUN npm run build

# Build stage for Python
FROM python:3.13-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.13-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy Python code
COPY code/ .

# Copy built UI from ui-builder
COPY --from=ui-builder /app/ui/dist ./ui/dist

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]