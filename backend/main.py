from datetime import datetime
import os
import uuid
import json
from dotenv import load_dotenv
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, get_jwt_identity, jwt_required
import pandas as pd
from PIL import Image
from flask import Flask, render_template, request, jsonify, send_file, redirect, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from concurrent.futures import ThreadPoolExecutor, as_completed
from openai import OpenAI
from google.cloud import vision

# -------------------- Load .env --------------------
load_dotenv()

# -------------------- External API Config --------------------
# Check if credentials are passed via GitHub Actions secret
google_credentials_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")

if google_credentials_json:
    # Running in CI/CD: write credentials to a temporary file
    creds_path = os.path.join(os.getcwd(), "gcp_credentials.json")
    with open(creds_path, "w") as f:
        f.write(google_credentials_json)
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = creds_path
else:
    # Running locally: use your local file path
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.getenv(
        "GOOGLE_APPLICATION_CREDENTIALS",
        "/Users/g.o.a.t/Downloads/PB-main/midyear-karma-456808-i7-7c468449720a.json"
    )

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

client = None
if not os.getenv("PYTEST_RUNNING"):   # <-- seulement si pas en test
    client = OpenAI(api_key=OPENAI_API_KEY)

# -------------------- Folders --------------------
UPLOAD_FOLDER = "uploads"
PROCESSED_FOLDER = "processed"
RESULT_FOLDER = "result"
for folder in [UPLOAD_FOLDER, PROCESSED_FOLDER, RESULT_FOLDER]:
    os.makedirs(folder, exist_ok=True)

# -------------------- Flask init --------------------
app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "default_secret")
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv("DATABASE_URL", "sqlite:///users.db")
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# JWT & limits
app.config.update(
    JWT_SECRET_KEY=os.getenv("JWT_SECRET_KEY", "change_me"),
    JWT_TOKEN_LOCATION=['headers'],
    JWT_HEADER_NAME='Authorization',
    JWT_HEADER_TYPE='Bearer',
    MAX_CONTENT_LENGTH=32 * 1024 * 1024,  # 32 MB
)
jwt = JWTManager(app)

# CORS
CORS(app, resources={
    r"/*": {
        "origins": ["*"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Authorization", "Content-Type"]
    }
})

db = SQLAlchemy(app)

# -------------------- Login Manager --------------------
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True)
    password = db.Column(db.String(150))

class Scan(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    timestamp = db.Column(
        db.DateTime,
        default=lambda: datetime.now().astimezone()
    )
    image_paths = db.Column(db.Text)  # JSON list
    result_json = db.Column(db.Text)  # JSON list

with app.app_context():
    db.create_all()

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# -------------------- Utils --------------------
def clean_folder(folder):
    for f in os.listdir(folder):
        try:
            os.remove(os.path.join(folder, f))
        except FileNotFoundError:
            pass

def convert_heic_to_png(src, dest):
    os.system(f'sips -s format png "{src}" --out "{dest}" > /dev/null 2>&1')

def compress_image(input_path, output_path, max_width=1600, quality=90):
    with Image.open(input_path) as img:
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        width_percent = max_width / float(img.size[0])
        height_size = int((float(img.size[1]) * float(width_percent)))
        img = img.resize((max_width, height_size), Image.LANCZOS)
        img.save(output_path, format='JPEG', optimize=True, quality=quality)

def extract_text_google_vision(image_path):
    vision_client = vision.ImageAnnotatorClient()
    with open(image_path, "rb") as image_file:
        content = image_file.read()
    image = vision.Image(content=content)
    response = vision_client.text_detection(image=image)
    if response.error.message:
        raise Exception(f"Google Vision API error: {response.error.message}")
    return response.text_annotations[0].description if response.text_annotations else ""

def parse_spine_line(line):
    if len(line.strip()) < 10:
        return None
    prompt = f'''Here is the text found on a book spine:\n"{line}"\n
Return ONLY a strict JSON like this:

{{
  "Title": "...",
  "Author(s)": "...",
  "Edition": "...",
  "Publisher": "...",
  "ISBN": "...",
  "Year": "..."
}}'''
    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are a librarian assistant. Reply ONLY with a strictly valid JSON."},
                {"role": "user", "content": prompt}
            ],
            # For this model, temperature must be the default (1). Do not change it.
        )
        content = response.choices[0].message.content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.endswith("```"):
            content = content[:-3]
        data = json.loads(content)
        data["Raw OCR Text"] = line
        return data
    except Exception as e:
        print(f"❌ GPT error for '{line[:20]}...': {e}")
        return None

# -------------------- CORS headers after_request --------------------
@app.after_request
def add_cors_headers(resp):
    resp.headers['Access-Control-Allow-Origin'] = '*'
    resp.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
    resp.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    return resp

# -------------------- Pages --------------------
@app.route("/")
@login_required
def index():
    return render_template("index.html", username=current_user.username)

@app.route('/processed/<path:filename>')
def serve_processed_image(filename):
    processed_dir = os.path.join(os.getcwd(), 'processed')
    return send_from_directory(processed_dir, filename)

# -------------------- API: Mock --------------------
@app.route("/mockUpload", methods=["POST"])
def mock_upload():
    try:
        mock_books = [
            {
                "Title": "The Little Prince",
                "Author(s)": "Antoine de Saint-Exupéry",
                "Edition": "Gallimard Edition",
                "Publisher": "Gallimard Jeunesse",
                "ISBN": "9782070612758",
                "Year": "2018",
                "Raw OCR Text": "Le Petit Prince - Antoine de Saint-Exupéry - Gallimard Jeunesse - ISBN 9782070612758"
            },
            {
                "Title": "The Stranger",
                "Author(s)": "Albert Camus",
                "Edition": "Folio Collection",
                "Publisher": "Gallimard",
                "ISBN": "9782070360022",
                "Year": "1942",
                "Raw OCR Text": "L'Étranger - Albert Camus - Gallimard - ISBN 9782070360022"
            },
            {
                "Title": "Les Misérables",
                "Author(s)": "Victor Hugo",
                "Edition": "Classic Edition",
                "Publisher": "Pocket",
                "ISBN": "9782266234913",
                "Year": "1862",
                "Raw OCR Text": "Les Misérables - Victor Hugo - Pocket - ISBN 9782266234913"
            }
        ]
        return jsonify({"message": "Mock processing completed", "data": mock_books})
    except Exception as e:
        print(f"❌ Error in mock: {e}")
        return jsonify({"error": str(e)}), 500

# -------------------- API: History / Deletion (JWT) --------------------
@app.route("/scanHistory", methods=["GET"])
@jwt_required()
def scan_history():
    user_id = int(get_jwt_identity())
    print(f"userId: {user_id}")
    scans = Scan.query.filter_by(user_id=user_id).order_by(Scan.timestamp.desc()).all()

    result = []
    for scan in scans:
        result.append({
            "id": scan.id,
            "user_id": scan.user_id,
            "timestamp": scan.timestamp.isoformat(),
            "images": json.loads(scan.image_paths),
            "ocr_result": json.loads(scan.result_json)
        })
    return jsonify(result)

@app.route("/delete-scans", methods=["POST"])
@jwt_required()
def delete_scans():
    try:
        data = request.get_json(silent=True) or {}
        ids = data.get("ids", [])
        for scan_id in ids:
            scan = Scan.query.get(scan_id)
            if scan:
                db.session.delete(scan)
        db.session.commit()
        return jsonify({"message": "Scans deleted successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------- API: Mobile Upload (JWT) --------------------
@app.route("/appUpload", methods=["POST"])
@jwt_required()
def upload_no_excel():
    try:
        current_user_id = int(get_jwt_identity())

        if not request.content_type or "multipart/form-data" not in request.content_type:
            return jsonify({"error": "Send multipart/form-data with one or more 'images' files."}), 400

        files = request.files.getlist("images")
        if not files:
            return jsonify({"error": "No file received (expected key: 'images')."}), 400

        books_structured = []
        image_paths = []

        with ThreadPoolExecutor(max_workers=4) as executor:
            futures = []

            for f in files:
                name = str(uuid.uuid4())
                ext = os.path.splitext(f.filename)[1]
                upload_path = os.path.join(UPLOAD_FOLDER, name + ext)
                f.save(upload_path)
                print(f"📂 Saved file: {upload_path}")

                if ext.lower() == ".heic":
                    img_path = os.path.join(PROCESSED_FOLDER, name + ".png")
                    convert_heic_to_png(upload_path, img_path)
                else:
                    img_path = upload_path

                compressed_path = os.path.join(PROCESSED_FOLDER, name + ".jpg")
                compress_image(img_path, compressed_path)
                print(f"🖼️ Compressed: {compressed_path}")

                image_paths.append(compressed_path)

                text = extract_text_google_vision(compressed_path)
                lines = [l for l in text.split('\n') if len(l.strip()) > 10]
                print(f"🔍 {len(lines)} lines extracted by OCR")

                for line in lines:
                    futures.append(executor.submit(parse_spine_line, line))

            for fut in as_completed(futures):
                try:
                    result = fut.result()
                    if result:
                        books_structured.append(result)
                except Exception as e:
                    print(f"⚠️ Error processing a line: {e}")

        # Save history
        scan = Scan(
            user_id=current_user_id,
            image_paths=json.dumps(image_paths),
            result_json=json.dumps(books_structured)
        )
        db.session.add(scan)
        db.session.commit()

        return jsonify({"message": "Processing completed", "data": books_structured})

    except Exception as e:
        print(f"❌ Server error: {e}")
        return jsonify({"error": str(e)}), 500

# -------------------- API: Web Upload (session login_required) --------------------
@app.route("/upload", methods=["POST"])
@login_required
def upload():
    files = request.files.getlist("images")
    if not files:
        return jsonify({"error": "No file uploaded"}), 400

    books_structured = []
    futures = []

    with ThreadPoolExecutor(max_workers=4) as executor:
        for f in files:
            name = str(uuid.uuid4())
            ext = os.path.splitext(f.filename)[1]
            upload_path = os.path.join(UPLOAD_FOLDER, name + ext)
            f.save(upload_path)

            if ext.lower() == ".heic":
                img_path = os.path.join(PROCESSED_FOLDER, name + ".png")
                convert_heic_to_png(upload_path, img_path)
            else:
                img_path = upload_path

            compressed_path = os.path.join(PROCESSED_FOLDER, name + ".jpg")
            compress_image(img_path, compressed_path)
            text = extract_text_google_vision(compressed_path)
            lines = [l for l in text.split('\n') if len(l.strip()) > 10]
            for line in lines:
                futures.append(executor.submit(parse_spine_line, line))

        for fut in as_completed(futures):
            result = fut.result()
            if result:
                books_structured.append(result)

    username = current_user.username.lower()
    user_folder = os.path.join(RESULT_FOLDER, username)
    os.makedirs(user_folder, exist_ok=True)

    excel_name = f"books_{uuid.uuid4().hex[:8]}.xlsx"
    output_excel = os.path.join(user_folder, excel_name)
    pd.DataFrame(books_structured).to_excel(output_excel, index=False)

    clean_folder(UPLOAD_FOLDER)
    clean_folder(PROCESSED_FOLDER)

    return jsonify({"message": "Processing completed", "data": books_structured, "file": excel_name})

@app.route("/download/<filename>")
@login_required
def download(filename):
    username = current_user.username.lower()
    user_folder = os.path.join(RESULT_FOLDER, username)
    filepath = os.path.join(user_folder, filename)

    if not os.path.exists(filepath):
        print(f"❌ File not found: {filepath}")
        return "File not found", 404

    return send_file(filepath, as_attachment=True)

# -------------------- Auth API (manual, as before) --------------------
@app.route("/applogin", methods=["POST"])
def api_login():
    username = request.form.get("username") or (request.json and request.json.get("username"))
    password = request.form.get("password") or (request.json and request.json.get("password"))

    if not username or not password:
        return jsonify({"success": False, "message": "Username and password required"}), 400

    user = User.query.filter_by(username=username).first()
    if user and check_password_hash(user.password, password):
        access_token = create_access_token(identity=str(user.id))
        response_data = {
            "success": True,
            "message": "Login successful",
            "username": user.username,
            "access_token": access_token
        }
        print("Login response JSON:", json.dumps(response_data))
        return jsonify(response_data), 200

    return jsonify({"success": False, "message": "Invalid credentials"}), 401

@app.route("/appregister", methods=["POST"])
def api_register():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "message": "Missing JSON body"}), 400

    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"success": False, "message": "Username and password required"}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({"success": False, "message": "User already exists"}), 409

    hashed_password = generate_password_hash(password)
    new_user = User(username=username, password=hashed_password)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({"success": True, "message": "Registration successful"})

# -------------------- Web auth --------------------
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]
        user = User.query.filter_by(username=username).first()
        if user and check_password_hash(user.password, password):
            login_user(user)
            return redirect("/")
        return "Invalid credentials"
    return render_template("login.html")

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form["username"]
        password = generate_password_hash(request.form["password"])
        if User.query.filter_by(username=username).first():
            return "User already exists"
        new_user = User(username=username, password=password)
        db.session.add(new_user)
        db.session.commit()
        return redirect("/login")
    return render_template("register.html")

@app.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect("/login")

# -------------------- JWT helpers & health --------------------
@jwt.unauthorized_loader
def jwt_missing_token(msg):
    return jsonify({"error": f"missing/invalid token: {msg}"}), 401

@jwt.invalid_token_loader
def jwt_invalid(msg):
    return jsonify({"error": f"invalid token: {msg}"}), 422

@jwt.expired_token_loader
def jwt_expired(jwt_header, jwt_payload):
    return jsonify({"error": "token expired"}), 401

@app.route("/me", methods=["GET"])
@jwt_required()
def me():
    return jsonify({"user_id": int(get_jwt_identity())})

@app.route("/health")
def health():
    return jsonify({"ok": True})

# -------------------- Run --------------------
if __name__ == "__main__":
    # same auto-start behavior
    app.run(debug=True, host="0.0.0.0")
