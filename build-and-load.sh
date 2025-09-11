#!/bin/bash

set -e  # Salir si algo falla

echo "🔧 Preparando entorno para Minikube..."

# 1. Revertir al Docker del host
eval $(minikube docker-env -u)

# 2. Construir imágenes en el host
echo "🐳 Construyendo imágenes Docker en el host..."

docker build -t usuarios-service:latest ./backend/usuarios
docker build -t tokens-service:latest ./backend/tokens
docker build -t transacciones-service:latest ./backend/transacciones

# 3. Exportar imágenes como archivos tar
echo "📦 Exportando imágenes..."

docker save usuarios-service:latest -o usuarios-service.tar
docker save tokens-service:latest -o tokens-service.tar
docker save transacciones-service:latest -o transacciones-service.tar

# 4. Cargar imágenes en Minikube
echo "📥 Cargando imágenes en Minikube..."

minikube image load usuarios-service.tar
minikube image load tokens-service.tar
minikube image load transacciones-service.tar

# 5. Verificar que las imágenes estén disponibles
echo "🔍 Verificando imágenes en Minikube..."
eval $(minikube docker-env)
docker images | grep -E "usuarios-service|tokens-service|transacciones-service"

echo "✅ Imágenes listas para desplegar en Kubernetes"
kubectl apply -f k8s/pv.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/usuarios-deployment.yaml
kubectl apply -f k8s/tokens-deployment.yaml
kubectl apply -f k8s/transacciones-deployment.yaml

echo "Pods"
echo "kubectl get pods"

echo "Compartir puertos"
echo "kubectl port-forward service/usuarios-svc 8001:8000 > /dev/null 2>&1 &"
echo "kubectl port-forward service/tokens-svc 8002:8000 > /dev/null 2>&1 &"
echo "kubectl port-forward service/transacciones-svc 8003:8000 > /dev/null 2>&1 &"