# 📱 DM Store — Admin App

A Flutter-based administration application for managing the DM Store e-commerce system. The app allows administrators to manage products, categories, orders, banners, users, and notifications through Firebase services.

---

## ✨ Features

### 🛠️ Admin Management

* **Authentication** — Secure admin login with Firebase Authentication
* **Dashboard** — Overview of store statistics and recent activities
* **Product Management** — Add, edit, delete, search, and manage product inventory
* **Category Management** — Create, update, and remove product categories
* **Banner Management** — Manage promotional banners displayed in the user app
* **Order Management** — View, update, and track customer orders in real time
* **User Management** — View customer information and account details
* **Push Notifications** — Send notifications to users via Firebase Cloud Messaging (FCM)
* **Customer Chat** — Real-time chat with customers using Firebase

---

## ✨ Development

0. Before running the project, install Flutter:

https://docs.flutter.dev/install

1. Install dependencies

```bash
flutter pub get
```

2. Run the project

```bash
flutter run
```

---

## 🏗️ Architecture & Tech Stack

| Layer            | Technology                                                                        |
| ---------------- | --------------------------------------------------------------------------------- |
| Framework        | Flutter                                                                           |
| Backend          | Firebase (Firestore, Authentication, Cloud Functions, Cloud Messaging, App Check) |
| State Management | BLoC / Cubit, Provider, GetX                                                      |
| Chart            | FL Chart                                                                          |
| Notifications    | Firebase Cloud Messaging (FCM)                                                    |
