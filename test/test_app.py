import json
import os
import io
import pytest
from unittest.mock import patch
from main import app, db, User, Scan, RESULT_FOLDER
from werkzeug.security import generate_password_hash

@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'  # DB en mémoire
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
        yield client
        with app.app_context():
            db.drop_all()

# ------------------ Helpers ------------------

def register_user(client, username="testuser", password="testpass"):
    return client.post("/appregister", json={"username": username, "password": password})

def login_user(client, username="testuser", password="testpass"):
    return client.post("/applogin", json={"username": username, "password": password})

# ------------------ BASE TESTS ------------------

def test_health_endpoint(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json() == {"ok": True}

def test_register_and_login(client):
    res = register_user(client)
    assert res.status_code == 200
    assert res.get_json()["success"]

    res = login_user(client)
    data = res.get_json()
    assert res.status_code == 200
    assert data["success"] is True
    assert "access_token" in data

def test_register_duplicate_user(client):
    register_user(client)
    res = register_user(client)
    assert res.status_code == 409
    assert res.get_json()["message"] == "User already exists"

def test_login_invalid_credentials(client):
    res = login_user(client, password="wrongpass")
    assert res.status_code == 401
    assert res.get_json()["success"] is False

def test_scan_history_requires_token(client):
    res = client.get("/scanHistory")
    assert res.status_code == 401

def test_scan_history_with_token(client):
    register_user(client)
    login_res = login_user(client)
    token = login_res.get_json()["access_token"]

    with app.app_context():
        user = User.query.filter_by(username="testuser").first()
        scan = Scan(user_id=user.id, image_paths=json.dumps([]), result_json=json.dumps([]))
        db.session.add(scan)
        db.session.commit()

    res = client.get("/scanHistory", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    data = res.get_json()
    assert len(data) == 1
    assert "id" in data[0]

def test_delete_scans(client):
    register_user(client)
    login_res = login_user(client)
    token = login_res.get_json()["access_token"]

    with app.app_context():
        user = User.query.filter_by(username="testuser").first()
        scan = Scan(user_id=user.id, image_paths=json.dumps([]), result_json=json.dumps([]))
        db.session.add(scan)
        db.session.commit()
        scan_id = scan.id

    res = client.post("/delete-scans", json={"ids": [scan_id]}, headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert res.get_json()["message"] == "Scans deleted successfully"

# ------------------ EXTRA TESTS ------------------

def test_mock_upload(client):
    res = client.post("/mockUpload")
    data = res.get_json()
    assert res.status_code == 200
    assert data["message"] == "Mock processing completed"
    assert len(data["data"]) == 3

def test_download_file_not_found(client):
    with app.app_context():
        user = User(username="webuser", password=generate_password_hash("1234"))
        db.session.add(user)
        db.session.commit()

    client.post("/login", data={"username": "webuser", "password": "1234"})
    res = client.get("/download/missing.xlsx")
    assert res.status_code == 404
    assert b"File not found" in res.data

def test_me_endpoint(client):
    register_user(client)
    login_res = login_user(client)
    token = login_res.get_json()["access_token"]

    res = client.get("/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert "user_id" in res.get_json()

def test_applogin_missing_fields(client):
    res = client.post("/applogin", json={"username": "only_username"})
    assert res.status_code == 400
    assert res.get_json()["message"] == "Username and password required"

def test_appregister_missing_body(client):
    res = client.post("/appregister", data="{}", content_type="application/json")
    assert res.status_code == 400
    assert res.get_json()["message"] == "Missing JSON body"

def test_download_with_user_folder(client):
    with app.app_context():
        user = User(username="john", password=generate_password_hash("doe"))
        db.session.add(user)
        db.session.commit()

    client.post("/login", data={"username": "john", "password": "doe"})

    username = "john"
    user_folder = os.path.join(app.config.get("RESULT_FOLDER", RESULT_FOLDER), username)
    os.makedirs(user_folder, exist_ok=True)
    filepath = os.path.join(user_folder, "dummy.xlsx")
    with open(filepath, "w") as f:
        f.write("fake excel")

    res = client.get("/download/dummy.xlsx")
    assert res.status_code == 200

def test_delete_scans_with_invalid_id(client):
    register_user(client)
    login_res = login_user(client)
    token = login_res.get_json()["access_token"]

    res = client.post("/delete-scans", json={"ids": [999]}, headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert res.get_json()["message"] == "Scans deleted successfully"

def test_jwt_helpers(client):
    res = client.get("/scanHistory")
    assert res.status_code == 401
    assert "missing/invalid token" in res.get_json()["error"]

    res = client.get("/scanHistory", headers={"Authorization": "Bearer faketoken"})
    assert res.status_code in (401, 422)

def test_login_web(client):
    with app.app_context():
        user = User(username="webuser", password=generate_password_hash("1234"))
        db.session.add(user)
        db.session.commit()

    res = client.post("/login", data={"username": "webuser", "password": "1234"})
    assert res.status_code in (200, 302)

def test_register_web(client):
    res = client.post("/register", data={"username": "newuser", "password": "abcd"})
    assert res.status_code in (200, 302)

# ------------------ BOOSTER TESTS ------------------

def test_appupload_wrong_content_type(client):
    register_user(client)
    login_res = login_user(client)
    token = login_res.get_json()["access_token"]

    res = client.post("/appUpload", headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    assert res.status_code == 400
    assert "multipart/form-data" in res.get_json()["error"]

def test_appupload_no_files(client):
    register_user(client)
    login_res = login_user(client)
    token = login_res.get_json()["access_token"]

    res = client.post("/appUpload", data={}, headers={"Authorization": f"Bearer {token}"}, content_type="multipart/form-data")
    assert res.status_code == 400
    assert "No file received" in res.get_json()["error"]

def test_upload_web_no_files(client):
    with app.app_context():
        user = User(username="webtest", password=generate_password_hash("123"))
        db.session.add(user)
        db.session.commit()

    client.post("/login", data={"username": "webtest", "password": "123"})
    res = client.post("/upload", data={}, content_type="multipart/form-data")
    assert res.status_code == 400
    assert "No file uploaded" in res.get_json()["error"]

def test_download_not_found_file(client):
    with app.app_context():
        user = User(username="ghost", password=generate_password_hash("pass"))
        db.session.add(user)
        db.session.commit()
    client.post("/login", data={"username": "ghost", "password": "pass"})
    res = client.get("/download/not_exists.xlsx")
    assert res.status_code == 404

def test_jwt_expired_handler(client):
    from main import jwt_expired
    with app.app_context():
        res, code = jwt_expired({}, {})
        assert code == 401
        assert "token expired" in res.json["error"]

def test_parse_spine_line_returns_none_for_short_line():
    from main import parse_spine_line
    result = parse_spine_line("short")
    assert result is None

@patch("main.compress_image", return_value=None)
@patch("main.extract_text_google_vision", return_value="This is a fake book line with more than ten chars")
@patch("main.parse_spine_line", return_value={"Title": "FakeBook", "Author(s)": "Tester", "Edition": "1st", "Publisher": "Nowhere", "ISBN": "0000", "Year": "2025", "Raw OCR Text": "fake"})
def test_appupload_with_mocked_ocr_and_gpt(mock_parse, mock_vision, mock_compress, client):
    register_user(client)
    login_res = login_user(client)
    token = login_res.get_json()["access_token"]

    data = {
        "images": (io.BytesIO(b"fake image data"), "test.jpg")
    }
    res = client.post("/appUpload", data=data, content_type="multipart/form-data",
                      headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    json_data = res.get_json()
    assert json_data["message"] == "Processing completed"
    assert any("Title" in book for book in json_data["data"])
