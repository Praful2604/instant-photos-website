

https://github.com/user-attachments/assets/e5bb7ad8-1379-46ea-ab43-4aebb8eccabe



# 📸 Instant Photos

A full-stack photo management and sharing platform built with **Flutter Web**, **Firebase**, and a **Python FastAPI** backend. Designed for photographers and event organizers to capture, manage, and deliver event photos to clients — powered by **AI face recognition**.

---

## 🚀 Features

### 👤 Admin (Photographer)
- Secure login & signup
- Create and manage events
- Upload photos to events
- Generate QR codes for events
- Manage digital albums
- View all uploaded photos
- Manage client subscriptions
- Integrated payment processing via **Razorpay**

### 👥 Client (Photo Viewer)
- OTP-based login (no password needed)
- Scan QR code to access event gallery
- Upload a selfie to find matching photos using **face recognition**
- Save favorite photos to personal digital album
- Download photos

### 🌐 Landing Page
- Hero section with call-to-action
- Features & key benefits showcase
- E-album demo section
- Subscription plans info
- Testimonials & FAQ
- About section

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web |
| Navigation | Go Router |
| UI | Material Design 3, Google Fonts (Poppins), Lottie |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Cloud Functions | Firebase Functions (Node.js) |
| AI Backend | Python FastAPI + face_recognition |
| Payments | Razorpay |
| QR Code | qr_flutter, mobile_scanner |

---

## 📁 Project Structure

```
instant-photos-website/
├── lib/
│   ├── main.dart                        # App entry point, Firebase init
│   ├── firebase_options.dart            # Firebase config
│   ├── routes/
│   │   └── app_routes.dart             # Go Router routes
│   └── screens/
│       ├── landing_page_screens/       # Public landing page
│       ├── admin_auth_pages/           # Admin login / signup
│       ├── admin_pages/                # Admin dashboard & features
│       ├── customer_auth_pages/        # Customer login / signup
│       └── client_pages/              # Client gallery & OTP login
│
├── backend/                            # Python FastAPI (face recognition)
│   ├── main.py
│   └── requirements.txt
│
├── functions/                          # Firebase Cloud Functions
│   └── index.js
│
└── assets/                             # Static assets
```

---

## 🔗 App Routes

| Route | Description |
|---|---|
| `/` | Landing / Home page |
| `/admin/login` | Admin login |
| `/admin/signup` | Admin signup |
| `/admin/dashboard` | Admin dashboard |
| `/customer/login` | Customer login |
| `/customer/signup` | Customer signup |
| `/client/otp` | Client OTP login |
| `/client/gallery/:qrCode` | Client photo gallery |

---

## ⚙️ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.5.4)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Python 3.8+ (for face recognition backend)
- Node.js (for Firebase Cloud Functions)

### 1. Clone the Repository

```bash
git clone https://github.com/Praful2604/instant-photos-website.git
cd instant-photos-website
```

### 2. Flutter Setup

```bash
flutter pub get
flutter run -d chrome
```

### 3. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication**, **Firestore**, and **Storage**
3. Replace `lib/firebase_options.dart` with your project's config
4. Deploy Cloud Functions:

```bash
cd functions
npm install
firebase deploy --only functions
```

### 4. Python Backend Setup (Face Recognition)

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

> **Note:** The backend requires a `serviceAccountKey.json` from your Firebase project. Download it from Firebase Console → Project Settings → Service Accounts. **Never commit this file to git.**

---

## 🔐 Environment & Secrets

- `backend/serviceAccountKey.json` — Firebase service account key (**gitignored, never commit**)
- Firebase config is handled via `lib/firebase_options.dart`

---

## 🧠 How Face Recognition Works

1. Admin uploads event photos to Firebase Storage under `event-images/{qrCode}/`
2. Client scans the event QR code and uploads a selfie
3. The FastAPI backend downloads event photos and compares face encodings
4. Matched photos are returned as signed URLs for the client to view and download

---

## 💳 Payments

Payments are handled via **Razorpay** (`razorpay_web`). Admins can manage subscription plans and process payments from the admin dashboard.

---

## 📦 Key Dependencies

```yaml
firebase_auth, cloud_firestore, firebase_storage  # Firebase
go_router                                          # Navigation
google_fonts, lottie, flip_card                   # UI
qr_flutter, mobile_scanner                        # QR Code
image_picker, cached_network_image                # Images
razorpay_web                                       # Payments
http                                               # API calls to FastAPI
```

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

---

## 📄 License

This project is for educational/portfolio purposes.
