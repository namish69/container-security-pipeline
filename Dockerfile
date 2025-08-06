FROM python:3.11-slim
WORKDIR /app
COPY app.py .
RUN apt-get update && apt-get upgrade -y && \
    pip install Flask setuptools==78.1.1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
EXPOSE 5000
CMD ["python", "app.py"]
