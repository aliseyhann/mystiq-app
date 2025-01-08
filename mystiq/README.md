# MystiQ Fortune App
# Overview
MystiQ is a Flutter-based app combining astrology and coffee fortune-telling with modern technology. It supports regular users and fortune tellers with tailored features for each role.

# Features
Profile Page
    Edit profile (photo, email, name).
    Manage notification preferences.
    Subscription packages (placeholder).
    Delete account option.
# Main Pages
    For Regular Users: Personalized features like horoscope readings.
    For Fortune Tellers: Manage requests and chats.
    Chat with RabbitMQ
    Real-time chat between regular users and fortune tellers.
    Initiate chat from the answered fortunes section in the Inbox.
    "Messages" section for chat history:
    Regular Users: Added under Inbox.
    ortune Tellers: Added under Fortune Requests.
# Features:
    Message delivery & seen status.
    Messages auto-delete after 24 hours.
    Pending Work
    Fix notification issues on iOS (Swift) and Android (Kotlin).
    Implement and test RabbitMQ chat functionality.
    Tech Stack
# Frontend: Flutter.
# Backend: MongoDB, RabbitMQ (for messaging).


# Setup
Clone the repo: "git clone https://github.com/your-repo/mystiq_fortune_app.git"
Install dependencies: "flutter pub get"
Run the app: "flutter run"
