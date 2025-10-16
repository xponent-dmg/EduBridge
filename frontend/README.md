# EduBridge - Micro-Internship Platform

EduBridge is a platform connecting students with companies for micro-internships and short-term tasks. Students can complete tasks to build their portfolios, while companies can find talented individuals.

## Features

### For Students

- Browse available tasks from companies
- Submit solutions for tasks
- Track submission status and feedback
- Build a professional portfolio
- Earn EduPoints for completed tasks

### For Companies

- Post tasks for students
- Review and grade submissions
- Find talented students for potential recruitment
- Manage company profile and tasks

### For Admins

- Manage users, tasks, and submissions
- Monitor platform activity
- Handle administrative functions

## Technical Overview

### Architecture

- **Frontend**: Flutter for cross-platform mobile app
- **Backend**: Node.js with Express
- **Database**: PostgreSQL with Supabase
- **Authentication**: Supabase Auth

### State Management

- Provider pattern for state management
- Clean architecture with separation of concerns

### Key Components

- **Models**: Data structures for users, tasks, submissions, etc.
- **Providers**: State management for different features
- **Services**: API client, authentication service
- **UI Components**: Reusable widgets for consistent design

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode for mobile deployment
- Node.js and npm for backend

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/edubridge.git
cd edubridge
```

2. Install frontend dependencies:

```bash
cd frontend
flutter pub get
```

3. Install backend dependencies:

```bash
cd ../backend
npm install
```

4. Configure environment variables:

   - Create a `.env` file in the backend directory
   - Set up Supabase credentials in the frontend config

5. Run the app:

```bash
# Start backend server
cd backend
npm start

# Run Flutter app
cd ../frontend
flutter run
```

## Project Structure

### Frontend

```
frontend/
├── lib/
│   ├── models/           # Data models
│   ├── pages/            # Screen UI
│   ├── providers/        # State management
│   ├── services/         # API and auth services
│   ├── theme/            # App theme configuration
│   ├── widgets/          # Reusable UI components
│   ├── app.dart          # App configuration
│   └── main.dart         # Entry point
├── assets/               # Images and other assets
└── pubspec.yaml          # Dependencies
```

### Backend

```
backend/
├── config/               # Configuration files
├── controllers/          # Request handlers
├── middleware/           # Custom middleware
├── routes/               # API routes
└── server.js             # Entry point
```

## Dependencies

### Frontend

- flutter: Flutter SDK
- provider: State management
- http: API requests
- supabase_flutter: Supabase client
- file_picker: File selection
- shared_preferences: Local storage
- flutter_svg: SVG rendering
- cached_network_image: Image caching
- flutter_secure_storage: Secure storage
- fl_chart: Data visualization

### Backend

- express: Web framework
- supabase: Supabase client
- jsonwebtoken: JWT authentication
- multer: File uploads
- cors: CORS support

## Configuration

### Supabase Configuration

The app uses Supabase for authentication and database. Configure your Supabase credentials in `frontend/lib/config.dart`:

```dart
final String supabaseUrl = 'YOUR_SUPABASE_URL';
final String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### Backend Configuration

Configure your backend URL in `frontend/lib/config.dart`:

```dart
final String backendBaseUrl = 'YOUR_BACKEND_URL';
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
