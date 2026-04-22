# Use the official Python 3.12 slim image as the base
# slim = smaller image, fewer vulnerabilities
FROM python:3.12-slim

# Set the working directory inside the container
# All subsequent commands run from here
WORKDIR /app

# Copy requirements first — before the app code
# This way Docker caches the pip install layer
# and only re-runs it if requirements.txt changes
COPY requirements.txt .

# Install Python dependencies
# --no-cache-dir keeps the image smaller
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app code into the container
COPY . .

# Start the app using uvicorn (ASGI server for FastAPI)
# Listens on all interfaces (0.0.0.0) on port 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]