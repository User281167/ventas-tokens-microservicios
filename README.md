
---

```markdown
# 🧱 Aplicación Web con Microservicios (FastAPI + Docker)

Este proyecto está compuesto por tres microservicios independientes que se comunican entre sí mediante HTTP. Cada uno se ejecuta en su propio contenedor Docker.

---

## 🔹 Microservicios

### 1. **Usuarios**

- Archivo: `usuarios.json`
```json
[
  { "id": 1, "nombre": "Ana", "saldo": 100 },
  { "id": 2, "nombre": "Luis", "saldo": 150 }
]
```

### 2. **Tokens**

- Archivo: `tokens.json`
```json
[
  { "id": 101, "nombre": "Gato Cósmico", "imagen": "gato.jpg", "precio": 50, "vendido": false },
  { "id": 102, "nombre": "Paisaje Lunar", "imagen": "luna.jpg", "precio": 70, "vendido": false }
]
```

### 3. **Transacciones**

- Archivo: `transacciones.json`
```json
[
  { "id": 1, "usuarioId": 1, "tokenId": 101, "fecha": "2025-09-10T17:00:00Z" }
]
```

---

## 📦 Dockerfile básico para cada servicio

```dockerfile
FROM python:3.11-slim
WORKDIR /app

COPY main.py ./
COPY data ./data

RUN pip install --no-cache-dir fastapi uvicorn httpx

ENV DATA_PATH=/app/data/<archivo>.json
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Reemplaza `<archivo>.json` por el nombre correspondiente: `usuarios.json`, `tokens.json`, o `transacciones.json`.

---

## 🚀 Construcción y ejecución

Desde la carpeta de cada servicio:

```bash
docker build -t <nombre-del-servicio> .
docker run -d -p <puerto-local>:8000 <nombre-del-servicio>
```

Ejemplos:

```bash
docker build -t usuarios-service .
docker run -d -p 3001:8000 usuarios-service

docker build -t tokens-service .
docker run -d -p 3002:8000 tokens-service

docker build -t transacciones-service .
docker run -d -p 3003:8000 transacciones-service
```

---

## 📂 Estructura del proyecto

```
backend/
├── usuarios/
│   ├── main.py
│   ├── usuarios.json
│   ├── Dockerfile
├── tokens/
│   ├── main.py
│   ├── tokens.json
│   ├── Dockerfile
├── transacciones/
│   ├── main.py
│   ├── transacciones.json
│   ├── Dockerfile
```

---

## ✅ Pruebas básicas

```bash
curl http://localhost:3001/health
curl http://localhost:3002/tokens
curl http://localhost:3003/tx
```

---

