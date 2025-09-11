from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json, os, threading


app = FastAPI(title="usuarios-service")
DATA_PATH = os.getenv("DATA_PATH", "/app/data/usuarios.json")
_lock = threading.Lock()


class UserIn(BaseModel):
    nombre: str
    saldo: float


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
    return {"status": "ok", "service": "usuarios"}


@app.get("/users")
async def list_users():
    return _read()


@app.get("/users/{uid}")
async def get_user(uid: int):
    users = _read()
    for u in users:
        if u["id"] == uid:
            return u
    raise HTTPException(status_code=404, detail="user not found")


@app.post("/users", status_code=201)
async def create_user(u: UserIn):
    users = _read()
    nid = max([x["id"] for x in users] + [0]) + 1
    user = {"id": nid, "nombre": u.nombre, "saldo": u.saldo}
    users.append(user)
    _write(users)
    return user
