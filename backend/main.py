from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, storage
import face_recognition
import os
import uuid
import shutil
from datetime import timedelta  # Required for V4 expiration

# ---------------- INIT APP ----------------
app = FastAPI()

# This handles the API communication between Flutter and FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- FIREBASE INIT ----------------
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(
    cred,
    {"storageBucket": "instant-photos-9a258.firebasestorage.app"},
)

bucket = storage.bucket()

TEMP_DIR = "temp"
os.makedirs(TEMP_DIR, exist_ok=True)

# ---------------- QR VALIDATION ----------------
@app.get("/check-qr")
async def check_qr(qr_code: str):
    prefix = f"event-images/{qr_code}/"
    blobs = bucket.list_blobs(prefix=prefix, max_results=1)
    return {"valid": any(blobs)}

# ---------------- FACE MATCH ----------------
@app.post("/face-match")
async def face_match(
    qr_code: str = Form(...),
    file: UploadFile = File(...),
):
    selfie_path = f"{TEMP_DIR}/{uuid.uuid4()}.jpg"

    with open(selfie_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    try:
        unknown_img = face_recognition.load_image_file(selfie_path)
        unknown_encodings = face_recognition.face_encodings(unknown_img)
    finally:
        if os.path.exists(selfie_path):
            os.remove(selfie_path)

    if not unknown_encodings:
        return []

    unknown_encoding = unknown_encodings[0]
    matched_urls = []

    blobs = bucket.list_blobs(prefix=f"event-images/{qr_code}/")

    for blob in blobs:
        if not blob.name.lower().endswith((".jpg", ".jpeg", ".png")):
            continue

        temp_img = f"{TEMP_DIR}/{uuid.uuid4()}.jpg"
        blob.download_to_filename(temp_img)

        try:
            img = face_recognition.load_image_file(temp_img)
            encodings = face_recognition.face_encodings(img)

            for enc in encodings:
                match = face_recognition.compare_faces(
                    [unknown_encoding], enc, tolerance=0.5
                )[0]

                if match:
                    # FIX: Use V4 signatures for better compatibility with Flutter Web
                    signed_url = blob.generate_signed_url(
                        version="v4",
                        expiration=timedelta(minutes=60),
                        method="GET"
                    )
                    matched_urls.append(signed_url)
                    break
        finally:
            if os.path.exists(temp_img):
                os.remove(temp_img)

    return matched_urls


# ---------------- RUN SERVER ----------------
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)

















    #Run this code by using this cmd
    # python -m venv venv
    # venv\Scripts\activate
    # pip install fastapi uvicorn firebase-admin face-recognition python-multipart
    # pip install cmake
    # pip install dlib
    # pip install face-recognition
    # uvicorn main:app --host 0.0.0.0 --port 5000 --reload

    # Test By Using
    # http://127.0.0.1:5000/docs