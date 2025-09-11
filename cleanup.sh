#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"
}

echo "🧹 === LIMPIEZA COMPLETA DEL ENTORNO ==="
echo ""

# Preguntar confirmación
read -p "¿Estás seguro de que quieres limpiar todo el entorno? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operación cancelada"
    exit 1
fi

log "Eliminando port-forwards activos..."
pkill -f "kubectl port-forward" || true

log "Eliminando todos los recursos de Kubernetes..."
kubectl delete all --all --ignore-not-found
kubectl delete pvc --all --ignore-not-found  
kubectl delete pv --all --ignore-not-found

log "Configurando entorno Docker de Minikube..."
eval $(minikube docker-env)

log "Eliminando imágenes Docker personalizadas..."
docker image rm -f usuarios-service:latest tokens-service:latest transacciones-service:latest 2>/dev/null || true

log "Limpiando datos del volumen en Minikube..."
minikube ssh "sudo rm -rf /mnt/data/*" 2>/dev/null || true

log "Reiniciando Minikube..."
minikube stop
minikube start --memory=2048mb --cpus=2

echo ""
log "✅ Entorno completamente limpio y listo para un nuevo despliegue"
log "Ejecuta ./deploy.sh para desplegar de nuevo"