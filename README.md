# Unideal - P2P Marketplace

Unideal is a modern Peer-to-Peer (P2P) marketplace application designed to facilitate buying, selling, and auctioning items directly between users. The system leverages a powerful **Flutter** mobile application and a scalable **Supabase** backend.

## 🚀 Project Overview

The project is structured to ensure high performance and ease of development:

- **`mobile_app/`**: The core Flutter application for Android and iOS.
- **`unidealsupa/`**: Supabase configuration, migrations, and edge functions.
- **`backend/`**: (Legacy) Original Node.js/MongoDB API (being migrated to Supabase).

## ✨ Features

- **User Authentication**: Secure authentication powered by Supabase Auth (JWT).
- **Marketplace Listings**: Real-time item listings with seamless image uploads.
- **Dynamic Auctions**: Interactive bidding system for auction-style selling.
- **Smart Transactions**: QR code integration for secure transaction verification.
- **Rich UI**: Smooth animations and a premium interface using `flutter_animate`.

## 🛠️ Tech Stack

### Backend & Infrastructure
- **Platform**: Supabase
- **Database**: PostgreSQL (with Realtime capabilities)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (Original migration from Cloudinary)

### Mobile App
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Networking**: `supabase_flutter` & `http`
- **Animations**: `flutter_animate`

## 🌿 Git Workflow

We follow a professional branching strategy to maintain code quality. Please refer to [CONTRIBUTING.md](file:///d:/Unideal/CONTRIBUTING.md) for full details.

- **`main`**: Production-ready code.
- **`develop`**: Main integration branch for development.
- **`feature/*`**: Individual features (e.g., `feature/chat-system`).
- **`bugfix/*`**: Urgent or minor bug fixes.

## 🏁 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0.0+)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (optional, for local development)

### Mobile App Setup

1.  Navigate to the mobile app directory:
    ```bash
    cd mobile_app
