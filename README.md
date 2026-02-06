# Unideal - P2P Marketplace

Unideal is a Peer-to-Peer (P2P) marketplace application designed to facilitate buying, selling, and auctioning items directly between users. The system comprises a robust Node.js backend and a cross-platform Flutter mobile application.

## Project Structure

The project is organized into two main directories:

- **`backend/`**: Contains the RESTful API server built with Node.js, Express, and MongoDB.
- **`mobile_app/`**: Contains the client-side mobile application built with Flutter.

## Features

- **User Authentication**: Secure sign-up and login functionality using JWT.
- **Marketplace Listings**: Users can post items for sale with details and images.
- **Auctions**: Support for auctioning items with bidding capabilities.
- **Image Management**: Integration with Cloudinary for efficient image storage and retrieval.
- **QR Code Integration**: Uses `qr_flutter` for generating/scanning QR codes, likely for verifying transactions or profile sharing.

## Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB (with Mongoose)
- **Authentication**: JSON Web Tokens (JWT) & bcryptjs
- **File Storage**: Cloudinary (via `multer-storage-cloudinary`)

### Mobile App
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Networking**: http
- **Local Storage**: shared_preferences

## Getting Started

### Prerequisites
- Node.js (v16+ recommended)
- Flutter SDK (3.0.0+)
- MongoDB instance (Local or Atlas)

### Backend Setup

1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```

2.  Install dependencies:
    ```bash
    npm install
    ```

3.  Configure Environment Variables:
    Create a `.env` file in the `backend/` directory with the following keys:
    ```env
    PORT=5000
    MONGO_URI=<your_mongodb_connection_string>
    JWT_SECRET=<your_jwt_secret>
    CLOUDINARY_CLOUD_NAME=<your_cloud_name>
    CLOUDINARY_API_KEY=<your_api_key>
    CLOUDINARY_API_SECRET=<your_api_secret>
    ```

4.  Start the server:
    ```bash
    # For development (with nodemon)
    npm run dev
    
    # For production
    npm start
    ```

### Mobile App Setup

1.  Navigate to the mobile app directory:
    ```bash
    cd mobile_app
    ```

2.  Install dependencies:
    ```bash
    flutter pub get
    ```

3.  Run the application:
    Make sure you have a connected device or running emulator.
    ```bash
    flutter run
    ```
    *Note: If connecting to a local backend from an Android emulator, ensure your API calls use `10.0.2.2` instead of `localhost`.*

## License

[Add License Information Here]
