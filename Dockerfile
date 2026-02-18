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

# Install Python dependencies
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all repository files (app.py, analysis.py, database.py, etc.)
COPY --chown=user . .

# Expose the port Hugging Face expects
EXPOSE 7860

# Run the FastAPI server which also launches your Telegram bot logic
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860"]
