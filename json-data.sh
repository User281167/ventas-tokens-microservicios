#!/bin/bash

echo "🔧 Creando archivos JSON iniciales..."

# Crear usuarios.json con datos de ejemplo
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
  }
]
EOF'

# Crear tokens.json con datos de ejemplo
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
  }
]
EOF'

# Crear transacciones.json vacío
kubectl exec deployment/transacciones-deployment -- sh -c 'cat > /data/transacciones.json << "EOF"
[]
EOF'

echo "✅ Archivos creados!"

echo "🔍 Verificando archivos:"
kubectl exec deployment/usuarios-deployment -- ls -la /data/
kubectl exec deployment/usuarios-deployment -- cat /data/usuarios.json

echo "🧪 Probando endpoints:"
echo "curl http://localhost:8001/users"
echo "curl http://localhost:8002/tokens" 
echo "curl http://localhost:8003/transacciones"