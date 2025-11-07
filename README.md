# 📚 CourseVerse - Online Learning Platform

A full-stack online learning platform built with Spring Boot backend and Flutter frontend, featuring Firebase authentication and AWS S3 storage.

---

## 🚀 Features

- 🔐 **Firebase Authentication** - Secure user authentication
- 📖 **Course Management** - Create and manage courses
- 🎥 **Video Lessons** - Support for video content
- 📝 **Rich Content** - Text, images, and multimedia support
- ☁️ **Cloud Storage** - AWS S3 for file uploads
- 📱 **Cross-Platform** - Android, iOS, Web, Windows, macOS, Linux support

---

## 🏗️ Tech Stack

### Backend

- **Framework**: Spring Boot 3.x
- **Language**: Java 17+
- **Authentication**: Firebase Admin SDK
- **Cloud Storage**: AWS S3
- **Build Tool**: Maven

### Frontend

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **Authentication**: Firebase Auth
- **HTTP Client**: Dio
- **Platforms**: Android, iOS, Web, Desktop (Windows, macOS, Linux)

---

## 📋 Prerequisites

### Backend

- Java 17 or higher
- Maven 3.6+
- Firebase account with a project created
- AWS account with S3 bucket configured

### Frontend

- Flutter SDK 3.x or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase CLI (optional, for configuration)

---

## ⚙️ Setup Instructions

### 🔒 Security First!

**IMPORTANT**: This project uses sensitive credentials. Before pushing to GitHub:

1. **Read the [SECURITY.md](SECURITY.md)** file
2. **Run the cleanup script**: `.\cleanup-sensitive-files.ps1`
3. **Rotate all exposed credentials** if any were previously committed

### 1️⃣ Backend Setup

#### Step 1: Clone the repository

```bash
git clone https://github.com/ShantanuDas-8013/CourseVerse.git
cd CourseVerse/backend
```

#### Step 2: Configure application.properties

```bash
cd src/main/resources
cp application.properties.example application.properties
```

Edit `application.properties` and add your credentials:

```properties
# AWS Credentials
spring.cloud.aws.credentials.access-key=YOUR_AWS_ACCESS_KEY
spring.cloud.aws.credentials.secret-key=YOUR_AWS_SECRET_KEY
spring.cloud.aws.region.static=YOUR_AWS_REGION
app.aws.s3.bucket-name=YOUR_BUCKET_NAME
```

#### Step 3: Add Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Save as `firebase-service-account-key.json` in `src/main/resources/`

#### Step 4: Build and run

```bash
# Build the project
mvn clean install

# Run the application
mvn spring-boot:run
```

The backend will start on `http://localhost:8080`

### 2️⃣ Frontend Setup

#### Step 1: Navigate to frontend

```bash
cd ../frontend
```

#### Step 2: Install dependencies

```bash
flutter pub get
```

#### Step 3: Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Download `google-services.json` for Android
3. Place in `android/app/`

For other platforms, use FlutterFire CLI:

```bash
firebase login
flutterfire configure
```

#### Step 4: Configure API endpoint

For local development, the default URL (`http://localhost:8080/api/v1`) works for desktop.

For Android emulator, update the URL in `lib/core/services/api_service.dart`:

```dart
static const String _baseUrl = 'http://10.0.2.2:8080/api/v1';
```

For production, use environment variables:

```bash
flutter build --dart-define=API_BASE_URL=https://your-api.com/api/v1
```

#### Step 5: Run the app

```bash
# Run on connected device
flutter run

# Or specify a device
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d android       # Android
```

---

## 📁 Project Structure

```
CourseVerse/
├── backend/                    # Spring Boot backend
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/courseverse/backend/
│   │   │   │   ├── controller/      # REST controllers
│   │   │   │   ├── service/         # Business logic
│   │   │   │   ├── model/           # Data models
│   │   │   │   ├── repository/      # Data access
│   │   │   │   ├── security/        # Security config
│   │   │   │   └── config/          # App configuration
│   │   │   └── resources/
│   │   │       ├── application.properties.example
│   │   │       └── firebase-service-account-key.json (not in git)
│   │   └── test/
│   └── pom.xml
│
├── frontend/                   # Flutter frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                # App-level code
│   │   ├── core/               # Core utilities
│   │   │   ├── models/         # Data models
│   │   │   ├── services/       # API & services
│   │   │   └── widgets/        # Shared widgets
│   │   └── features/           # Feature modules
│   ├── android/
│   │   └── app/
│   │       └── google-services.json (not in git)
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
│
├── .gitignore                  # Root gitignore
├── SECURITY.md                 # Security guidelines
├── cleanup-sensitive-files.ps1 # Security cleanup script
└── README.md                   # This file
```

---

## 🔐 Security Considerations

### Sensitive Files (Never commit these!)

- ❌ `backend/src/main/resources/application.properties`
- ❌ `backend/src/main/resources/firebase-service-account-key.json`
- ❌ `frontend/android/app/google-services.json`
- ❌ `backend/target/` (build artifacts)

### Safe to Commit

- ✅ `.gitignore` files
- ✅ `application.properties.example`
- ✅ `firebase_options.dart` (public Firebase config)
- ✅ Source code files

**Always refer to [SECURITY.md](SECURITY.md) for detailed security guidelines.**

---

## 🧪 Testing

### Backend Tests

```bash
cd backend
mvn test
```

### Frontend Tests

```bash
cd frontend
flutter test
```

---

## 📦 Building for Production

### Backend

```bash
cd backend
mvn clean package
# JAR file will be in target/backend-0.0.1-SNAPSHOT.jar
```

### Frontend

#### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS

```bash
flutter build ios --release
```

#### Web

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-api.com/api/v1
```

#### Windows

```bash
flutter build windows --release
```

---

## 🚀 Deployment

### Backend Deployment (Example: AWS EC2)

1. Build the JAR file
2. Upload to EC2 instance
3. Set environment variables:
   ```bash
   export AWS_ACCESS_KEY=your_key
   export AWS_SECRET_KEY=your_secret
   ```
4. Run: `java -jar backend-0.0.1-SNAPSHOT.jar`

### Frontend Deployment

#### Web (Firebase Hosting)

```bash
flutter build web --release
firebase deploy --only hosting
```

#### Mobile (App Stores)

- Follow platform-specific guidelines for Google Play Store and Apple App Store

---

## 🐛 Troubleshooting

### Backend Issues

**Problem**: Firebase authentication fails

- **Solution**: Verify `firebase-service-account-key.json` is in the correct location
- Check Firebase Console for project ID

**Problem**: AWS S3 upload fails

- **Solution**: Verify AWS credentials in `application.properties`
- Check IAM user has S3 permissions
- Verify bucket name and region

### Frontend Issues

**Problem**: Cannot connect to backend

- **Solution**: Check API URL in `api_service.dart`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- Verify backend is running

**Problem**: Firebase authentication not working

- **Solution**: Verify `google-services.json` is present
- Run `flutterfire configure` again
- Check Firebase Console for app configuration

---

## 📝 API Documentation

### Base URL

```
http://localhost:8080/api/v1
```

### Authentication

All requests (except public endpoints) require Firebase JWT token:

```
Authorization: Bearer <firebase_jwt_token>
```

### Endpoints

#### Courses

- `GET /courses` - Get all courses
- `GET /courses/{id}` - Get course by ID
- `POST /courses` - Create course (instructor only)
- `PUT /courses/{id}` - Update course
- `DELETE /courses/{id}` - Delete course

#### Users

- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update current user
- `POST /users/register` - Register new user

#### Lessons

- `GET /courses/{courseId}/lessons` - Get course lessons
- `POST /courses/{courseId}/lessons` - Create lesson
- `GET /lessons/{id}/content` - Get lesson content

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

**Important**: Always run security checks before committing!

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Authors

- **Shantanu Das** - [@ShantanuDas-8013](https://github.com/ShantanuDas-8013)

---

## 🙏 Acknowledgments

- Firebase for authentication and backend services
- AWS S3 for cloud storage
- Flutter team for the amazing framework
- Spring Boot community

---

## 📧 Contact

For questions or support, please open an issue on GitHub or contact the maintainers.

---

## ⚠️ Before Pushing to GitHub

**CRITICAL**: Before pushing this project to a public repository:

1. ✅ Run `.\cleanup-sensitive-files.ps1`
2. ✅ Verify `.gitignore` files are working
3. ✅ Rotate exposed AWS credentials
4. ✅ Regenerate Firebase service account keys
5. ✅ Review [SECURITY.md](SECURITY.md)

**Never commit sensitive credentials to version control!** 🔒
