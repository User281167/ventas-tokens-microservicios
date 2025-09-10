from fastapi import FastAPI
import json

app = FastAPI()


@app.get("/usuarios")
def listar_usuarios():
    with open("usuarios.json") as f:
        return json.load(f)
