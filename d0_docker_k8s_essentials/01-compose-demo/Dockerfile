FROM python:3.11-slim

# Set working directory
WORKDIR /code

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /code
USER appuser

# Expose port
EXPOSE 5000

# Command to run the application
CMD ["python", "app.py"]