#!/bin/bash

set -e  # Salir si algún comando falla

echo "🚀 === DESPLIEGUE COMPLETO DE MICROSERVICIOS EN KUBERNETES ==="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"
}

# 1. VERIFICAR Y CONFIGURAR MINIKUBE
log "Verificando estado de Minikube..."
if ! command -v minikube &> /dev/null; then
    error "Minikube no está instalado"
    exit 1
fi

if ! minikube status | grep -q "Running"; then
    log "Iniciando Minikube..."
    minikube start --memory=2048mb --cpus=2
else
    log "Minikube ya está corriendo ✅"
fi

# 2. CONFIGURAR ENTORNO DOCKER
log "Configurando entorno Docker de Minikube..."
eval $(minikube docker-env)

# 3. LIMPIAR DESPLIEGUES ANTERIORES
log "Limpiando despliegues anteriores..."
kubectl delete deployment usuarios-deployment --ignore-not-found
kubectl delete deployment tokens-deployment --ignore-not-found
kubectl delete deployment transacciones-deployment --ignore-not-found

kubectl delete service usuarios-svc --ignore-not-found
kubectl delete service tokens-svc --ignore-not-found
kubectl delete service transacciones-svc --ignore-not-found

kubectl delete pvc shared-pvc --ignore-not-found
kubectl delete pv shared-pv --ignore-not-found

# Matar port-forwards anteriores
warn "Limpiando port-forwards anteriores..."
pkill -f "kubectl port-forward" || true
sleep 2

# 4. CONSTRUIR IMÁGENES DOCKER
log "Construyendo imágenes Docker..."
log "  📦 Construyendo usuarios-service..."
docker build -t usuarios-service:latest ./backend/usuarios

log "  📦 Construyendo tokens-service..."
docker build -t tokens-service:latest ./backend/tokens

log "  📦 Construyendo transacciones-service..."
docker build -t transacciones-service:latest ./backend/transacciones

log "Verificando imágenes construidas:"
docker images | grep -E "(usuarios-service|tokens-service|transacciones-service)"

# 5. CONFIGURAR VOLUMEN PERSISTENTE
log "Creando directorio de datos en Minikube..."
minikube ssh "sudo mkdir -p /mnt/data && sudo chmod 777 /mnt/data"

# 6. DESPLEGAR MANIFIESTOS DE KUBERNETES
log "Aplicando manifiestos de Kubernetes..."

log "  📄 Aplicando PV y PVC..."
kubectl apply -f k8s/pv.yaml
kubectl apply -f k8s/pvc.yaml

log "  ⏳ Esperando que el PVC esté disponible..."
kubectl wait --for=condition=Bound pvc/shared-pvc --timeout=60s

log "  📄 Desplegando servicios..."
kubectl apply -f k8s/usuarios-deployment.yaml
kubectl apply -f k8s/tokens-deployment.yaml  
kubectl apply -f k8s/transacciones-deployment.yaml

# 7. ESPERAR QUE LOS PODS ESTÉN LISTOS
log "Esperando que los pods estén listos..."
log "  ⏳ Esperando usuarios..."
kubectl wait --for=condition=Ready pod -l app=usuarios --timeout=120s

log "  ⏳ Esperando tokens..."
kubectl wait --for=condition=Ready pod -l app=tokens --timeout=120s

log "  ⏳ Esperando transacciones..."
kubectl wait --for=condition=Ready pod -l app=transacciones --timeout=120s

log "Estado de los pods:"
kubectl get pods

# 8. INICIALIZAR DATOS
log "Inicializando datos de ejemplo..."

log "  📝 Creando usuarios.json..."
kubectl exec deployment/usuarios-deployment -- sh -c 'cat > /data/usuarios.json << "EOF"
[
  {
    "id": 1,
    "nombre": "Juan Pérez",
    "email": "juan@example.com",
    "avatar": "https://via.placeholder.com/150",
    "saldo": 1000.0
  },
  {
    "id": 2,
    "nombre": "María García", 
    "email": "maria@example.com",
    "avatar": "https://via.placeholder.com/150",
    "saldo": 1500.0
  },
  {
    "id": 3,
    "nombre": "Carlos López",
    "email": "carlos@example.com", 
    "avatar": "https://via.placeholder.com/150",
    "saldo": 750.0
  }
]
EOF'

log "  🪙 Creando tokens.json..."
kubectl exec deployment/tokens-deployment -- sh -c 'cat > /data/tokens.json << "EOF"
[
  {
    "id": 1,
    "nombre": "Token Oro",
    "imagen": "https://via.placeholder.com/200",
    "precio": 100.0,
    "vendido": false
  },
  {
    "id": 2,
    "nombre": "Token Plata",
    "imagen": "https://via.placeholder.com/200", 
    "precio": 50.0,
    "vendido": false
  },
  {
    "id": 3,
    "nombre": "Token Bronce",
    "imagen": "https://via.placeholder.com/200",
    "precio": 25.0,
    "vendido": true
  },
  {
    "id": 4,
    "nombre": "Token Diamante",
    "imagen": "https://via.placeholder.com/200",
    "precio": 500.0,
    "vendido": false
  }
]
EOF'

log "  💸 Creando transacciones.json..."
kubectl exec deployment/transacciones-deployment -- sh -c 'cat > /data/transacciones.json << "EOF"
[]
EOF'

log "Verificando archivos creados:"
kubectl exec deployment/usuarios-deployment -- ls -la /data/

# 9. CONFIGURAR PORT-FORWARDS
log "Configurando port-forwards..."
kubectl port-forward service/usuarios-svc 8001:8000 > /dev/null 2>&1 &
kubectl port-forward service/tokens-svc 8002:8000 > /dev/null 2>&1 &
kubectl port-forward service/transacciones-svc 8003:8000 > /dev/null 2>&1 &

log "Esperando que los port-forwards estén activos..."
sleep 5

# 10. PROBAR SERVICIOS
log "Probando servicios..."

test_endpoint() {
    local name=$1
    local url=$2
    if curl -s "$url" > /dev/null; then
        log "  ✅ $name: $url"
    else
        warn "  ⚠️ $name no responde todavía: $url"
    fi
}

test_endpoint "Usuarios Health" "http://localhost:8001/health"
test_endpoint "Tokens Health" "http://localhost:8002/health"
test_endpoint "Transacciones Health" "http://localhost:8003/health"

echo ""
log "🎯 DESPLIEGUE COMPLETADO EXITOSAMENTE!"
echo ""
echo -e "${BLUE}📋 INFORMACIÓN DE LOS SERVICIOS:${NC}"
echo "  👥 Usuarios:      http://localhost:8001"
echo "     - Health:      http://localhost:8001/health"
echo "     - Listar:      http://localhost:8001/users"
echo ""
echo "  🪙 Tokens:        http://localhost:8002"
echo "     - Health:      http://localhost:8002/health"
echo "     - Listar:      http://localhost:8002/tokens"
echo ""
echo "  💸 Transacciones: http://localhost:8003"
echo "     - Health:      http://localhost:8003/health"
echo "     - Listar:      http://localhost:8003/transacciones"
echo ""
echo -e "${BLUE}🛠️ COMANDOS ÚTILES:${NC}"
echo "  • Ver pods:       kubectl get pods"
echo "  • Ver servicios:  kubectl get services"
echo "  • Ver logs:       kubectl logs -l app=usuarios"
echo "  • Dashboard:      minikube dashboard"
echo ""
echo -e "${BLUE}🧪 PRUEBAS RÁPIDAS:${NC}"
echo "  curl http://localhost:8001/users"
echo "  curl http://localhost:8002/tokens"
echo "  curl http://localhost:8003/health"
echo ""
echo -e "${GREEN}✨ ¡Todo listo para usar! ✨${NC}"