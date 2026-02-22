# Use a slim Python image for efficiency
FROM python:3.9-slim

# Install system dependencies needed for Matplotlib and image generation
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libfreetype6-dev \
    pkg-config \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user (Security requirement for Hugging Face)
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH"

WORKDIR /app

# 🎯 CRITICAL FIX: Create entrypoint script to override DNS BEFORE app starts
USER root
RUN printf '#!/bin/sh\n\
echo "🌐 Setting DNS to Google (8.8.8.8, 8.8.4.4)"\n\
echo "nameserver 8.8.8.8" > /etc/resolv.conf\n\
echo "nameserver 8.8.4.4" >> /etc/resolv.conf\n\
echo "✅ DNS configured, starting app..."\n\
exec su user -c "$@"\n' > /docker-entrypoint.sh && \
chmod +x /docker-entrypoint.sh
USER user

# 🎯 Redirect cache directories to writable /tmp (HF requirement)
ENV NUMBA_CACHE_DIR=/tmp/numba_cache
ENV MPLCONFIGDIR=/tmp/matplotlib_cache
ENV XDG_CACHE_HOME=/tmp/hf_cache
ENV HF_HOME=/tmp/hf_cache
RUN mkdir -p /tmp/numba_cache /tmp/matplotlib_cache /tmp/hf_cache

# Install Python dependencies
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all repository files (app.py, analysis.py, database.py, etc.)
COPY --chown=user . .

# Expose the port Hugging Face expects
EXPOSE 7860

# 🎯 Use custom entrypoint to set DNS, then start app
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860"]
