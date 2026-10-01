from flask import Flask, jsonify

app = Flask(__name__)

# Valor ficticio para probar el detector. No es una credencial funcional.
DEMO_SECRET = "DEMO-ONLY-NOT-A-CREDENTIAL-123456"


@app.get("/")
def index():
    return jsonify(aplicacion="Docker DevSecOps Demo", estado="funcionando")


@app.get("/health")
def health():
    return jsonify(status="OK")


if __name__ == "__main__":
    # Inseguro para un despliegue: el depurador de desarrollo queda habilitado.
    app.run(host="0.0.0.0", port=5000, debug=True)
