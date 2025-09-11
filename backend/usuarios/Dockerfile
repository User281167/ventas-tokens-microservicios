FROM python:3.11-slim
WORKDIR /app

COPY main.py ./
COPY data ./data

RUN pip install --no-cache-dir fastapi uvicorn httpx

ENV DATA_PATH=/app/data/usuarios.json
ENV PORT=8000

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
