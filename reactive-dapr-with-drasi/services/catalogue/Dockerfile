# Stage 1: Build React app
FROM node:18-alpine as frontend-builder

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source files and build
COPY tsconfig*.json ./
COPY vite.config.ts ./
COPY tailwind.config.js ./
COPY postcss.config.js ./
COPY index.html ./
COPY src/ ./src/

RUN npm run build

# Stage 2: Python backend
FROM python:3.11-slim

WORKDIR /app

# Install nginx and supervisor
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy Python requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Python application code
COPY code/ ./code/

# Copy React build from previous stage
COPY --from=frontend-builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/sites-available/default

# Copy supervisor configuration
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 80

# Run supervisor to manage both nginx and uvicorn
CMD ["/docker-entrypoint.sh"]