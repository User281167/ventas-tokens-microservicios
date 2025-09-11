FROM python:3.11-slim
WORKDIR /app

# Copia el código y los datos
COPY main.py ./
COPY data ./data

# Instala dependencias
RUN pip install --no-cache-dir fastapi uvicorn httpx

# Define variables de entorno
ENV DATA_PATH=/app/data/tokens.json
ENV PORT=8000

EXPOSE 8000

# Comando para ejecutar el servicio
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
