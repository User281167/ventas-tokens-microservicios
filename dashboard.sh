#!/bin/bash

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

echo "📊 === CONFIGURANDO DASHBOARD DE KUBERNETES ==="
echo ""

log "Habilitando addon del dashboard..."
minikube addons enable dashboard

log "Habilitando metrics-server..."
minikube addons enable metrics-server

log "Esperando que el dashboard esté listo..."
kubectl wait --for=condition=Available deployment/kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

log "Creando ServiceAccount para acceso admin..."
kubectl create serviceaccount dashboard-admin-sa -n kubernetes-dashboard --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin-sa --dry-run=client -o yaml | kubectl apply -f -

log "Generando token de acceso..."
TOKEN=$(kubectl create token dashboard-admin-sa -n kubernetes-dashboard --duration=24h)

log "Eliminando port-forwards anteriores del dashboard..."
pkill -f "kubectl.*dashboard" || true
sleep 2

log "Configurando port-forward para el dashboard..."
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8080:80 > /dev/null 2>&1 &

log "Esperando que el port-forward esté activo..."
sleep 5

# Guardar token en archivo
echo "$TOKEN" > dashboard-token.txt

echo ""
echo -e "${BLUE}✅ DASHBOARD CONFIGURADO EXITOSAMENTE!${NC}"
echo ""
echo -e "${YELLOW}🔗 URL del Dashboard:${NC} http://localhost:8080"
echo ""
echo -e "${YELLOW}🔑 Token de acceso:${NC}"
echo "────────────────────────────────────────────────────────────────"
echo "$TOKEN"
echo "────────────────────────────────────────────────────────────────"
echo ""
echo -e "${BLUE}📋 Pasos para acceder (desde WSL):${NC}"
echo "1. 🌐 Abre tu navegador en Windows"
echo "2. 📍 Ve a: http://localhost:8080"
echo "3. 🔐 Selecciona 'Token' como método de login"
echo "4. 📋 Copia y pega el token de arriba"
echo "5. ✅ Haz clic en 'Sign In'"
echo ""
echo -e "${YELLOW}💾 El token también se guardó en: dashboard-token.txt${NC}"
echo ""

# Verificar conectividad
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
    echo -e "${GREEN}✅ Dashboard accesible en http://localhost:8080${NC}"
else
    echo -e "${YELLOW}⚠️ Verificando conectividad del dashboard...${NC}"
    sleep 3
    if curl -s -o /dev/null http://localhost:8080; then
        echo -e "${GREEN}✅ Dashboard funcionando correctamente${NC}"
    else
        echo -e "${YELLOW}⚠️ Si tienes problemas, ejecuta: kubectl get pods -n kubernetes-dashboard${NC}"
    fi
fi

echo ""
echo -e "${BLUE}🎯 El dashboard estará disponible mientras este script esté corriendo${NC}"
echo -e "${BLUE}🛑 Para detenerlo, presiona Ctrl+C${NC}"