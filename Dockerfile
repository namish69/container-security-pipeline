FROM python:3.11-slim
WORKDIR /app
COPY app.py .
RUN pip install Flask setuptools==78.1.1 \
 && adduser --disabled-password --gecos '' appuser
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
