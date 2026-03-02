# --- STAGE 1: BUILDER ---
FROM python:3.11-slim as builder
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install dependency untuk build
RUN apt-get update && apt-get install -y --no-install-recommends gcc

COPY requirements.txt .
# Build dependency ke format 'wheel' agar ringan
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# --- STAGE 2: RUNNER (Image Final) ---
FROM python:3.11-slim
WORKDIR /app

# Ambil hasil build dari STAGE 1
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# Install tanpa cache
RUN pip install --no-cache /wheels/*

# Copy kode aplikasi
COPY main.py test_main.py ./

# Praktik Keamanan Enterprise: Jangan jalankan container sebagai ROOT!
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]