from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(aplicacion="Docker DevSecOps Demo", estado="funcionando")


@app.get("/health")
def health():
    return jsonify(status="OK")


if __name__ == "__main__":
    # Se requiere el bind en todas las interfaces para el puerto publicado por Docker.
    app.run(host="0.0.0.0", port=5000, debug=False)  # nosec B104
