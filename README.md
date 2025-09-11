
---

# 🚀 Guía de Despliegue: Microservicios en Minikube

Este proyecto contiene tres microservicios independientes: **usuarios**, **tokens** y **transacciones**, desplegados en un clúster local de Kubernetes usando Minikube.

---

## 🧭 Requisitos previos

- Minikube instalado y funcionando
- Docker instalado
- `kubectl` configurado para usar Minikube
- Archivos de manifiesto Kubernetes en la carpeta `k8s/`
- Estructura del backend organizada por microservicio

---

## 🧱 Estructura del proyecto

```
backend/
├── usuarios/
├── tokens/
├── transacciones/
k8s/
├── pv.yaml
├── pvc.yaml
├── usuarios-deployment.yaml
├── tokens-deployment.yaml
├── transacciones-deployment.yaml
```

---

## 🧨 Despliegue paso a paso

### 1. Inicia Minikube

```bash
minikube start --memory=2048mb --force
```

---

### 2. Ejecuta el script de despliegue

```bash
./deploy.sh
```

Este script realiza lo siguiente:

- Configura el entorno Docker para Minikube
- Construye las imágenes Docker de los tres microservicios
- Elimina despliegues y servicios anteriores
- Crea el volumen persistente compartido
- Aplica los manifiestos de Kubernetes
- Espera que los pods estén listos
- Muestra el estado final del clúster

---

### 3. Verifica el estado

```bash
kubectl get pods
kubectl get services
```

---

### 4. Accede a los servicios desde tu máquina

Ejecuta los siguientes comandos para redirigir puertos:

```bash
kubectl port-forward service/usuarios-svc 8001:8000 &
kubectl port-forward service/tokens-svc 8002:8000 &
kubectl port-forward service/transacciones-svc 8003:8000 &
```

Luego puedes probar los endpoints:

```bash
curl http://localhost:8001/health
curl http://localhost:8002/tokens
curl http://localhost:8003/tx
```

---

### 5. Verifica los logs

```bash
kubectl logs -l app=usuarios --tail=20
```

---

## 🧪 Pruebas rápidas

Puedes usar el script `curl-test.sh` para probar la creación de usuarios, tokens y transacciones automáticamente.

---

## 🧹 Reinicio del clúster

Para detener el clúster:

```bash
minikube stop
```

Para reiniciarlo:

```bash
minikube start
```

---

## 📦 Notas adicionales

- Los archivos `.json` usados como base de datos se almacenan en un volumen persistente compartido (`/mnt/data`).
- Las imágenes Docker se construyen dentro del entorno de Minikube para evitar errores de `ImagePullBackOff`.

---
