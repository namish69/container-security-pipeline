FROM python:3.11-slim

WORKDIR /app
COPY app.py .

RUN pip install Flask setuptools==70.0.0

EXPOSE 5000
CMD ["python", "app.py"]
