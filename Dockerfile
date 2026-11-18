FROM python:3.12-slim

WORKDIR /app

# System deps for pypdf/python-docx are pure-Python; no extra system
# packages required beyond what the slim image already has.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Local upload storage; mount a volume here in docker-compose for persistence,
# or swap to the S3FileStorage backend for a real deployment (see
# app/services/file_storage.py).
RUN mkdir -p /app/uploads
ENV UPLOAD_DIR=/app/uploads

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
