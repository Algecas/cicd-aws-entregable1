from unittest.mock import MagicMock, patch

from app import app


def test_health():
    response = app.test_client().get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "OK"}


def test_saludo_returns_database_message():
    connection = MagicMock()
    cursor = connection.__enter__.return_value.cursor.return_value.__enter__.return_value
    cursor.fetchone.return_value = ("Hola desde la prueba",)

    with patch("app.get_connection", return_value=connection):
        response = app.test_client().get("/saludo")

    assert response.status_code == 200
    assert response.get_json() == {"mensaje": "Hola desde la prueba"}


def test_saludo_handles_empty_table():
    connection = MagicMock()
    cursor = connection.__enter__.return_value.cursor.return_value.__enter__.return_value
    cursor.fetchone.return_value = None

    with patch("app.get_connection", return_value=connection):
        response = app.test_client().get("/saludo")

    assert response.status_code == 200
    assert response.get_json() == {"mensaje": "No hay saludos disponibles"}


def test_saludo_hides_database_errors():
    with patch("app.get_connection", side_effect=RuntimeError("secret detail")):
        response = app.test_client().get("/saludo")

    assert response.status_code == 500
    assert response.get_json() == {"error": "No fue posible consultar el saludo"}
    assert b"secret detail" not in response.data


def test_ready_reports_success():
    connection = MagicMock()

    with patch("app.get_connection", return_value=connection):
        response = app.test_client().get("/ready")

    assert response.status_code == 200
    assert response.get_json() == {"status": "READY"}


def test_ready_reports_database_failure():
    with patch("app.get_connection", side_effect=RuntimeError("database unavailable")):
        response = app.test_client().get("/ready")

    assert response.status_code == 503
    assert response.get_json() == {"status": "NOT_READY"}
