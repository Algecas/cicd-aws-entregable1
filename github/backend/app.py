import logging
import os

import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "database"),
        database=os.getenv("DB_NAME", "saludos_db"),
        user=os.getenv("DB_USER", "saludos_user"),
        password=os.environ["DB_PASSWORD"],
        port=int(os.getenv("DB_PORT", "5432")),
        sslmode=os.getenv("DB_SSLMODE", "prefer"),
        connect_timeout=int(os.getenv("DB_CONNECT_TIMEOUT", "5")),
    )


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "OK"})


@app.route("/ready", methods=["GET"])
def ready():
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
        return jsonify({"status": "READY"})
    except Exception:
        app.logger.exception("Database readiness check failed")
        return jsonify({"status": "NOT_READY"}), 503


@app.route("/saludo", methods=["GET"])
def saludo():
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT mensaje
                    FROM saludos
                    ORDER BY RANDOM()
                    LIMIT 1;
                """)
                result = cursor.fetchone()

        if result:

            return jsonify({"mensaje": result[0]})

        return jsonify({"mensaje": "No hay saludos disponibles"})

    except Exception:
        app.logger.exception("Unable to retrieve greeting")
        return jsonify({"error": "No fue posible consultar el saludo"}), 500


if __name__ == "__main__":
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
    app.run(host="0.0.0.0", port=5000)
