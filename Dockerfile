FROM python:3.11-slim

WORKDIR /app
COPY app.py .

RUN pip install Flask setuptools==78.1.1

EXPOSE 5000
CMD ["python", "app.py"]
