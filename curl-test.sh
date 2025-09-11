#!/bin/bash

echo "🔍 Verificando salud de los servicios..."
curl -s http://localhost:3001/health | jq
curl -s http://localhost:3002/health | jq
curl -s http://localhost:3003/health | jq

echo -e "\n👤 Creando usuario..."
curl -s -X POST http://localhost:3001/users \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Carlos", "email": "carlos@example.com", "avatar": "carlos.png", "saldo": 200}' | jq

echo -e "\n🎨 Creando token..."
curl -s -X POST http://localhost:3002/tokens \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Estrella Fugaz", "imagen": "estrella.jpg", "precio": 80}' | jq

echo -e "\n📦 Listando tokens..."
curl -s http://localhost:3002/tokens | jq

echo -e "\n📦 Listando usuarios..."
curl -s http://localhost:3001/users | jq

echo -e "\n🔁 Creando transacción (usuarioId=1, tokenId=101)..."
curl -s -X POST http://localhost:3003/tx \
  -H "Content-Type: application/json" \
  -d '{"usuarioId": 1, "tokenId": 101}' | jq

echo -e "\n📜 Listando transacciones..."
curl -s http://localhost:3003/tx | jq
