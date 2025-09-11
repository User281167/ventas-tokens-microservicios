#!/bin/bash

echo "🔄 Configurando entorno Docker de Minikube..."
# Importante: configurar el entorno Docker de Minikube
eval $(minikube docker-env -u)

echo "🐳 Construyendo imágenes dentro del entorno Docker de Minikube..."
docker build -t usuarios-service:latest ./backend/usuarios
docker build -t tokens-service:latest ./backend/tokens
docker build -t transacciones-service:latest ./backend/transacciones

echo "📋 Verificando que las imágenes se crearon correctamente..."
docker images | grep -E "(usuarios-service|tokens-service|transacciones-service)"

echo "🧹 Limpiando deployments anteriores..."
kubectl delete deployment usuarios-deployment --ignore-not-found
kubectl delete deployment tokens-deployment --ignore-not-found
kubectl delete deployment transacciones-deployment --ignore-not-found

kubectl delete service usuarios-svc --ignore-not-found
kubectl delete service tokens-svc --ignore-not-found
kubectl delete service transacciones-svc --ignore-not-found

echo "📦 Creando directorio de datos en Minikube..."
minikube ssh "sudo mkdir -p /mnt/data && sudo chmod 777 /mnt/data"

echo "📄 Aplicando manifiestos de Kubernetes..."
kubectl apply -f k8s/pv.yaml
kubectl apply -f k8s/pvc.yaml

echo "⏳ Esperando que el PVC esté disponible..."
kubectl wait --for=condition=Bound pvc/shared-pvc --timeout=60s

kubectl apply -f k8s/usuarios-deployment.yaml
kubectl apply -f k8s/tokens-deployment.yaml
kubectl apply -f k8s/transacciones-deployment.yaml

echo "⏳ Esperando que los pods estén listos..."
kubectl wait --for=condition=Ready pod -l app=usuarios --timeout=120s
kubectl wait --for=condition=Ready pod -l app=tokens --timeout=120s
kubectl wait --for=condition=Ready pod -l app=transacciones --timeout=120s

echo "✅ Despliegue completo!"
echo "📊 Estado de los pods:"
kubectl get pods

echo "🔍 Para verificar los servicios:"
echo "kubectl get services"

echo "🌐 Para acceder a los servicios desde fuera del cluster:"
echo "kubectl port-forward service/usuarios-svc 8001:8000 &"
echo "kubectl port-forward service/tokens-svc 8002:8000 &"
echo "kubectl port-forward service/transacciones-svc 8003:8000 &"

echo "📄 Logs de usuarios:"
echo "kubectl logs -l app=usuarios --tail=20"