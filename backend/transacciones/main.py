from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os, json, threading, datetime
import httpx


app = FastAPI(title="transacciones-service")
DATA_PATH = os.getenv("DATA_PATH", "/app/data/transacciones.json")
USERS_URL = os.getenv("USERS_URL", "http://usuarios-svc:8000")
TOKENS_URL = os.getenv("TOKENS_URL", "http://tokens-svc:8000")
_lock = threading.Lock()


class TxIn(BaseModel):
    usuarioId: int
    tokenId: int
    fecha: str | None = None


def _read():
    if not os.path.exists(DATA_PATH):
        return []
    with _lock:
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            raw = f.read().strip() or "[]"
            return json.loads(raw)


def _write(obj):
    with _lock:
        with open(DATA_PATH, "w", encoding="utf-8") as f:
            json.dump(obj, f, ensure_ascii=False, indent=2)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "transacciones"}


@app.get("/tx")
async def list_tx():
    return _read()


@app.post("/tx", status_code=201)
async def create_tx(tx: TxIn):
    async with httpx.AsyncClient(timeout=5.0) as client:
        u = await client.get(f"{USERS_URL}/users/{tx.usuarioId}")
        if u.status_code != 200:
            raise HTTPException(status_code=400, detail="invalid usuarioId")
        t = await client.get(f"{TOKENS_URL}/tokens/{tx.tokenId}")
        if t.status_code != 200:
            raise HTTPException(status_code=400, detail="invalid tokenId")
        tjson = t.json()
        if tjson.get("vendido"):
            raise HTTPException(status_code=409, detail="token already sold")
        # marcar vendido en tokens
        await client.post(f"{TOKENS_URL}/tokens/{tx.tokenId}/marcar-vendido", json={"vendido": True})


    data = _read()
    nid = max([x.get("id", 0) for x in data] + [0]) + 1
    fecha = tx.fecha or datetime.datetime.utcnow().isoformat() + "Z"
    row = {"id": nid, "usuarioId": tx.usuarioId, "tokenId": tx.tokenId, "fecha": fecha}
    data.append(row)
    _write(data)
    return row