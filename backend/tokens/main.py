from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json, os, threading


app = FastAPI(title="tokens-service")
DATA_PATH = os.getenv("DATA_PATH", "/app/data/tokens.json")
_lock = threading.Lock()


class TokenIn(BaseModel):
    nombre: str
    imagen: str | None = None
    precio: float


class MarkSoldIn(BaseModel):
    vendido: bool = True


def _read():
    with _lock:
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            return json.load(f)


def _write(obj):
    with _lock:
        with open(DATA_PATH, "w", encoding="utf-8") as f:
            json.dump(obj, f, ensure_ascii=False, indent=2)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "tokens"}


@app.get("/tokens")
async def list_tokens():
    return _read()


@app.get("/tokens/{tid}")
async def get_token(tid: int):
    toks = _read()
    for t in toks:
        if t["id"] == tid:
            return t
    raise HTTPException(status_code=404, detail="token not found")


@app.post("/tokens", status_code=201)
async def create_token(t: TokenIn):
    toks = _read()
    nid = max([x["id"] for x in toks] + [0]) + 1
    tok = {"id": nid, "nombre": t.nombre, "imagen": t.imagen, "precio": t.precio, "vendido": False}
    toks.append(tok)
    _write(toks)
    return tok


@app.post("/tokens/{tid}/marcar-vendido")
async def mark_sold(tid: int, body: MarkSoldIn):
    toks = _read()
    for t in toks:
        if t["id"] == tid:
            t["vendido"] = bool(body.vendido)
            _write(toks)
            return t
    raise HTTPException(status_code=404, detail="token not found")