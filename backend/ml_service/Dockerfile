# Stage 1: Build python dependencies
FROM python:3.10-slim AS builder

WORKDIR /app

# Install system utilities needed for building wheels if any
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file first
COPY requirements.txt .

# Install packages to user local directory
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Run application
FROM python:3.10-slim AS runner

WORKDIR /app

# Copy dependency packages from the builder stage
COPY --from=builder /root/.local /root/.local
COPY . /app

# Ensure bin path is available
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Expose ports
EXPOSE 8000
EXPOSE 8501

# Clean CRLF from start.sh and make executable
RUN tr -d '\r' < start.sh > start_unix.sh && mv start_unix.sh start.sh && chmod +x start.sh

# Start application via start.sh script
CMD ["/bin/bash", "start.sh"]
