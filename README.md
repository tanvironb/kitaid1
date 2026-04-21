# KitaID  
**A Secure and Integrated Mobile App for Digital Identity in Malaysia**

---

## 👨‍💻 Project Team
- **Monir Sayed Abdulrashid** (2128031)  
- **Md Tanvir Ahmmed Shopno** (2219061)  

**Supervisor:**  
Dr. Zainatul Shima Abdullah  
Kulliyyah of Information and Communication Technology, IIUM

---

## 📱 Project Overview
KitaID is a cross-platform mobile application developed to modernize digital identity management and verification in Malaysia. The app provides a centralized, secure, and user-friendly platform that allows users to store, manage, and verify multiple identity documents digitally, reducing reliance on physical cards.

This project was developed as a **Final Year Project (FYP2)** for the **Bachelor of Information Technology (Hons)** at the **Kulliyyah of Information and Communication Technology (KICT), IIUM**.

📄 Full technical details are available in the **Final Report**: :contentReference[oaicite:0]{index=0}

---

## 🎯 Problem Statement
Malaysian citizens and foreign residents are required to carry multiple physical identity documents such as:
- MyKad  
- I-Kad  
- Passport  
- Driving License  

These physical documents are prone to **loss, damage, theft, forgery**, and **inefficient manual verification**. While some digital solutions exist (e.g., MyJPJ), they operate in isolation and do not provide a unified digital identity platform.

---

## 💡 Solution: KitaID
KitaID addresses these challenges by offering:
- A **centralized digital identity wallet**
- **QR-based identity verification**
- **Biometric authentication** (Face ID / Fingerprint)
- **Real-time notifications**
- **Secure document storage**

The app demonstrates how a national digital identity platform could function using modern mobile and cloud technologies.

---

## ✨ Key Features

### 👤 User Features
- Secure registration using IC/Passport number
- OTP-based authentication
- Biometric login (Face ID / Fingerprint / PIN)
- Digital storage of identity documents:
  - MyKad
  - I-Kad
  - Passport
  - Driving License
- QR code generation for identity verification
- Copy & share identity details (PDF export)
- Document expiry and verification notifications
- Multilingual support (English & Bahasa Melayu)
- Chatbot for FAQs and assistance
- Profile and account management
- Delete account & data control

### 🏢 Verification & Services
- QR-based identity verification for authorized parties
- Direct access to government and service portals (JPJ, Immigration, EMGS, etc.)
- Emergency contact shortcuts
- Recent services tracking

---

## 🛠️ Technology Stack

| Layer | Technology |
|-----|-----------|
| Frontend | Flutter (Dart) |
| Backend | Firebase |
| Authentication | Firebase Auth + OTP |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Functions |
| UI/UX Design | Figma |
| Version Control | GitHub |

---

### Other Packages / APIs
- Local Authentication
- QR Flutter
- Mobile Scanner
- Printing / PDF
- Shared Preferences
- URL Launcher

---

## Project Structure

```bash
kitaid1/
│
├── android/               # Android native configuration
├── ios/                   # iOS native configuration
├── lib/                   # Main Flutter application source code
├── assets/                # Images, icons, fonts, and other assets
├── functions/             # Firebase Cloud Functions
├── web/                   # Web support
├── windows/               # Windows support
├── macos/                 # macOS support
├── linux/                 # Linux support
├── test/                  # Flutter test files
├── .firebaserc            # Firebase project configuration
├── firebase.json          # Firebase settings
├── pubspec.yaml           # Flutter dependencies
└── README.md              # Project documentation

```

## Prerequisites

Before running this project, make sure your PC has the following installed:

- Git
- Visual Studio Code
- Flutter SDK
- Dart SDK (Usually included with Flutter)
- Android Studio (for Android SDK, emulator, and platform tools)
- Firebase CLI
- Node.js (required for Firebase Cloud Functions)
- A connected Android phone or Android emulator

---  


## 🧱 System Architecture
- Cross-platform Flutter mobile application (Android & iOS)
- Firebase backend for authentication, data storage, and real-time updates
- QR-based verification flow with controlled data exposure
- Modular and scalable architecture following Agile methodology

---

## 🔒 Security & Privacy
- Biometric authentication support
- Role-based access control
- Secure Firestore rules
- No direct exposure of sensitive data during QR verification
- Designed in alignment with **Malaysia’s PDPA principles**

---

## 🚧 Project Limitations
- No direct access to official government databases (academic constraint)
- Identity documents are manually uploaded for demonstration purposes
- Firebase used instead of national-level infrastructure
- Large-scale biometric validation and legal integration not implemented

---

## 🚀 Future Enhancements
- Direct integration with official government databases
- Dedicated verification interface for law enforcement
- Expanded multilingual support
- Advanced encryption and national-scale security compliance
- Full nationwide deployment as a government-backed platform

---

## 🌍 Sustainable Development Goals (SDGs)
KitaID supports:
- **SDG 9** – Industry, Innovation & Infrastructure  
- **SDG 16** – Peace, Justice & Strong Institutions  

By promoting secure digital infrastructure, transparent verification, and efficient public services.

---


## 1. How to Set Up the PC Environment
### Step 1: Install Git

Download and install Git from the official website.

After installation, check:
```bash
git --version
```

### Step 2: Install Flutter SDK

Download Flutter SDK and extract it to a folder, for example:
```bash
C:\src\flutter
```
Add Flutter to your system PATH:
```bash
C:\src\flutter\bin
```

Check installation:
```bash
flutter --version
```

### Step 3: Check Flutter Setup

Run:
```bash
flutter doctor
```
This command will tell you what is missing, such as Android SDK, licenses, or emulator setup.


### Step 4: Install Android Studio

Install Android Studio because Flutter Android development needs:

- Android SDK
- SDK Platform Tools
- SDK Command-line Tools
- Android Emulator

After installation, open Android Studio and install the required SDK components.


### Step 5: Accept Android Licenses
```bash
flutter doctor --android-licenses
```
Then run again:
```bash
flutter doctor
```

### Step 6: Install Node.js

Install Node.js because this project includes Firebase Cloud Functions.

Check installation:
```bash
node -v
npm -v
```

### Step 7: Install Firebase CLI
```bash
npm install -g firebase-tools
```
Check installation:
```bash
firebase --version
```

### Step 8: Clone the Repository
```bash
git clone https://github.com/tanvironb/kitaid1.git
cd kitaid1
```
---


## 2. How to Set Up Dart, Flutter, and Firebase in VS Code
### Step 1: Install VS Code Extensions

Open VS Code and install these extensions:

- Flutter
- Dart
- Firebase Explorer (optional)
- GitLens (optional)

### Step 2: Open the Project in VS Code
```bash
code .
```
Or open the folder manually in VS Code.

### Step 3: Verify Flutter in VS Code

In the VS Code terminal, run:
```bash
flutter doctor
```
If Flutter is properly detected, VS Code should show Flutter-related options such as:

- Run
- Debug
- Device selection

### Step 4: Install Flutter Packages

Inside the project root, run:
```bash
flutter pub get
```

### Step 5: Firebase Setup for the Flutter App

This project already contains Firebase-related configuration files, but on a new machine you still need to make sure Firebase is correctly connected to your own setup if needed.

General Firebase setup process:

1. Create or open a Firebase project in Firebase Console
2. Register your Android app
3. A dd the Firebase configuration file to the Flutter project
4. Enable required Firebase services:
5. Authentication
6. Firestore
7. Cloud Messaging
8. Storage
9. Functions

If using FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Step 6: Firebase Functions Setup

Move into the functions folder and install dependencies:
```bash
cd functions
npm install
cd ..
```
---

## 3. Additional Setup Notes
### Android SDK

Make sure Android SDK is installed and configured properly through Android Studio.

Useful command:
```bash
flutter doctor -v
```

### Emulator

At least one Android emulator should be created from Android Studio Device Manager.

### USB Debugging for Real Device

If you want to test on a real Android phone:

- Enable Developer Options
- Enable USB Debugging
- Connect the phone to the PC by USB
- Allow the debugging prompt on the phone

### Firebase Authentication Setup

If the app uses Firebase Authentication features, make sure the required sign-in methods are enabled in Firebase Console.

Example:

- Phone Authentication
- Email/Password (if used)
  
### Firestore and Storage Rules
###### If your project depends on Firestore and Storage, make sure their security rules are configured correctly in Firebase.
---

## 4. How to Run This Project in VS Code
### Step 1: Open the Project
```bash
cd kitaid1
code .
```
### Step 2: Get Packages
```bash
flutter pub get
```
### Step 3: Check Connected Devices
```bash
flutter devices
```
### Step 4: Run the Application
```bash
flutter run
```

If more than one device is connected, specify a device:
```bash
flutter run -d <device_id>
```
Example:
```bash
flutter run -d emulator-5554
```
You can also run it directly from VS Code by:

- selecting a device in the bottom bar
- pressing F5
- or clicking Run > Start Debugging

---

## 5. How to Run It on Android Emulator or Real Mobile
## Option A: Run on Android Emulator
### Step 1: Start an Emulator

Open Android Studio > Device Manager
Start one of your Android Virtual Devices (AVD).

Or check available emulators using:
```bash
flutter emulators
```
Launch one emulator:
```bash
flutter emulators --launch <emulator_id>
```
### Step 2: Confirm the Emulator Is Detected
```bash
flutter devices
```
### Step 3: Run the App
```bash
flutter run
```
Or specify the emulator:
```bash
flutter run -d emulator-5554
```

## Option B: Run on a Real Android Phone
### Step 1: Enable Developer Options

On your phone:

Open Settings
- Go to About Phone
- Tap Build Number several times until developer mode is enabled
  
### Step 2: Enable USB Debugging

In Developer Options, turn on:

- USB Debugging
  
### Step 3: Connect the Phone

- Connect your phone to your PC using a USB cable.

### Step 4: Verify the Device
```bash
flutter devices
```
Step 5: Run the App
```bash
flutter run
```
Or run specifically on the phone:
```bash
flutter run -d <device_id>
```
---

## Useful Flutter Commands

Clean the Project
```bash
flutter clean
```
Get Packages Again
```bash
flutter pub get
```
Check Flutter Environment
```bash
flutter doctor
```
List Devices
```bash
flutter devices
```
Run in Debug Mode
```bash
flutter run
```
Build APK
```bash
flutter build apk
```
Build App Bundle
```bash
flutter build appbundle
```

---

## Firebase Functions Commands

If you need to work with Firebase Cloud Functions:

Install dependencies
```bash
cd functions
npm install
```
Run local emulator for functions
```bash
npm run serve
```
Deploy functions
```bash
npm run deploy
```
View function logs
```bash
npm run logs
```
---

## Troubleshooting
### Flutter Doctor Issues

If something is not working, first run:
```bash
flutter doctor
```
Fix all major errors shown there.

### Packages Not Installing

Try:
```bash
flutter clean
flutter pub get
```
### Emulator Not Showing

Check:
```bash
flutter devices
flutter emulators
```
### Firebase Errors

Make sure:

- Firebase project is connected correctly
- Required services are enabled
- Configuration files are added correctly
- Firestore / Storage rules allow the required access
  
### Android Build Issues

Try:
```bash
flutter clean
flutter pub get
flutter run
```
---

## 📜 License
This project was developed for academic purposes as part of a Final Year Project (FYP2).  
All rights reserved by the authors.

---

## 📬 Contact
For inquiries or collaboration:
- Email: tahmmed2001@gmail.com

---

⭐ If you find this project useful, feel free to star the repository!
