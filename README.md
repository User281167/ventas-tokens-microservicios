Aplicación web microservicios con kubernets

### 🧱 Microservicios

#### 1. **Servicio de Usuario**

- Archivo: `usuarios.json`
- Contiene usuarios con ID, nombre, y saldo.
  json

```
[
  { "id": 1, "nombre": "Ana", "saldo": 100 },
  { "id": 2, "nombre": "Luis", "saldo": 150 }
]
```

#### 2. **Servicio de Producto (Token)**

- Archivo: `tokens.json`
- Contiene tokens con ID, nombre, imagen, precio y estado.
  json

```
[
  { "id": 101, "nombre": "Gato Cósmico", "imagen": "gato.jpg", "precio": 50, "vendido": false },
  { "id": 102, "nombre": "Paisaje Lunar", "imagen": "luna.jpg", "precio": 70, "vendido": false }
]
```

Simular trafico en este sercio y agregando otra instancia Pods

#### 3. **Servicio de Transacción**

- Archivo: `transacciones.json`
- Registra las compras realizadas.
  json

```
[
  { "id": 1, "usuarioId": 1, "tokenId": 101, "fecha": "2025-09-10T17:00:00Z" }
]
```

Tumbar este servicio

### 1. **Pods**

- Cada microservicio (Usuario, Producto, Transacción) se ejecuta en su propio **Pod**.
- Si simulas tráfico en el servicio de Producto y agregas otra instancia, estás creando **réplicas de Pods** para ese servicio.
- Esto te permite probar **escalabilidad horizontal**: cómo responde tu sistema cuando hay más carga.

### 2. **Services**

- Los **Services** en Kubernetes exponen tus Pods para que puedan comunicarse entre sí o recibir tráfico externo.
- Por ejemplo, el servicio de Transacción necesita acceder al servicio de Producto para verificar si un token está disponible.
- Puedes usar un **ClusterIP** para comunicación interna o un **NodePort/LoadBalancer** si quieres exponerlo hacia afuera.

### 3. **ReplicaSets \*\***/ \***\*Deployments**

- Cuando agregas otra instancia del servicio de Producto, lo haces mediante un **Deployment** que gestiona el número de réplicas.
- Esto te permite simular balanceo de carga y alta disponibilidad.

### 4. **Escenarios \*\***de \***\*fallos**

- Al “tumbar” el servicio de Transacción, estás simulando un **fallo de Pod**.
- Kubernetes lo detecta y puede reiniciarlo automáticamente si usas un Deployment con política de reinicio.
- Esto te permite probar la **resiliencia** de tu arquitectura.

### 5. **ConfigMaps \*\***/ \***\*Volumes \*\***(opcional)\*\*

- Si usas archivos JSON como almacenamiento, puedes montarlos como **volúmenes** o usar **ConfigMaps** para inyectar datos estáticos.
- Aunque no es obligatorio, te da más control sobre cómo se acceden y comparten esos archivos.

## 🧰 Tecnologías recomendadas por servicio

| Componente         | Tecnología sugerida                                      |
| ------------------ | -------------------------------------------------------- |
| Microservicios     | **Python + FastAPI**                                     |
| Comunicación       | <p>**HTTP REST**</p><p> (FastAPI lo maneja muy bien)</p> |
| Almacenamiento     | <p>**Archivos JSON locales**</p><p> (</p><p>, etc.)</p>  |
| Contenedores       | <p>**Docker**</p><p> para empaquetar cada servicio</p>   |
| Orquestación       | <p>**Kubernetes**</p><p> para desplegar y escalar</p>    |
| Simulación tráfico | <p></p><p></p><p></p>                                    |
| Logs/monitoring    |                                                          |

## 🐍 Estructura básica de un servicio con FastAPI

python

```
from fastapi import FastAPI
import json

app = FastAPI()

@app.get("/tokens")
def listar_tokens():
    with open("tokens.json") as f:
        tokens = json.load(f)
    return tokens
```

Empaquetas esto en un contenedor Docker y lo despliegas en Kubernetes.

## 📦 Dockerfile básico para FastAPI

Dockerfile

```
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install fastapi uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 🚀 Despliegue en Kubernetes

### 1. **Deployment**

Define cuántas réplicas quieres, qué imagen usar, y cómo iniciar el contenedor.

yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: servicio-producto
spec:
  replicas: 1
  selector:
    matchLabels:
      app: producto
  template:
    metadata:
      labels:
        app: producto
    spec:
      containers:
      - name: producto
        image: tu-imagen:latest
        ports:
        - containerPort: 8000
```

### 2. **Service**

Expone el Deployment dentro del clúster.

yaml

```
apiVersion: v1
kind: Service
metadata:
  name: producto-service
spec:
  selector:
    app: producto
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: ClusterIP
```

## 🧪 Simular tráfico y fallos

- usar `kubectl scale deployment` para agregar más réplicas.
- “tumbar” un servicio con `kubectl delete pod` y ver cómo Kubernetes lo reinicia.
- simular carga con `hey` o `k6` para ver cómo responde tu servicio de tokens.

```plaintext
backend/
├── usuarios/
│   ├── main.py                  # Lógica del microservicio de usuarios
│   ├── usuarios.json            # Datos simulados de usuarios
│   ├── Dockerfile               # Imagen Docker para usuarios
├── tokens/
│   ├── main.py                  # Lógica del microservicio de tokens
│   ├── tokens.json              # Datos simulados de tokens
│   ├── Dockerfile               # Imagen Docker para tokens
├── transacciones/
│   ├── main.py                  # Lógica del microservicio de transacciones
│   ├── transacciones.json       # Datos simulados de transacciones
│   ├── Dockerfile               # Imagen Docker para transacciones
├── k8s/
│   ├── usuarios-deployment.yaml         # Despliegue de usuarios en Kubernetes
│   ├── tokens-deployment.yaml           # Despliegue de tokens en Kubernetes
│   ├── transacciones-deployment.yaml    # Despliegue de transacciones en Kubernetes
│   ├── usuarios-service.yaml            # Service para usuarios
│   ├── tokens-service.yaml              # Service para tokens
│   ├── transacciones-service.yaml       # Service para transacciones
```

Entrar a la carpeta de servicio

uvicorn main:app --reload --port 8000

Desplegar

kubectl apply -f k8s/usuarios-configmap.yaml

kubectl apply -f k8s/usuarios-deployment.yaml

kubectl apply -f k8s/usuarios-service.yaml
