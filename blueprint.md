
# Project Blueprint

## Overview

This document outlines the architecture, features, and design of the Flutter application. It serves as a guide for developers to understand the project's structure and conventions.

## 1. Project Structure

The project follows a feature-based structure, where each feature is organized into its own directory. This promotes modularity and scalability.

```
/lib
|-- /modes
|   |-- /assistant
|   |   |-- assistant_service.dart
|   |-- /friend
|   |   |-- friend_service.dart
|   |-- /teacher
|   |   |-- teacher_service.dart
|   |-- mode_base.dart
|-- /screens
|   |-- intro_screen.dart
|   |-- main_screen.dart
|-- /service
|   |-- LunaBrain.dart
|-- main.dart
```

## 2. Features

### 2.1. Core
- **`main.dart`**: The entry point of the application. It initializes the app and sets up the main theme and routing.
- **`LunaBrain.dart`**: The core service that manages the AI's state and logic. It interacts with the different modes (Assistant, Friend, Teacher) to provide responses to the user.

### 2.2. Modes
The application has three distinct modes, each with its own personality and function:
- **Assistant Mode**: Provides helpful and informative responses.
- **Friend Mode**: Engages in friendly and casual conversation.
- **Teacher Mode**: Explains concepts and answers questions in an educational manner.

### 2.3. Screens
- **`intro_screen.dart`**: The first screen the user sees. It introduces the app and prompts the user to start.
- **`main_screen.dart`**: The main screen of the app, where the user interacts with the AI.

## 3. Design and Theming

The application uses the Material You design system, with a dynamic color palette generated from a seed color. The typography is based on the `google_fonts` package, and the theme is managed using the `provider` package.

- **Color Scheme**: A `ColorScheme` is generated from a seed color, `Colors.deepPurple`.
- **Typography**: The `Oswald`, `Roboto`, and `Open Sans` fonts are used for different text styles.
- **Theme Toggle**: The user can toggle between light and dark themes, or set the theme to follow the system settings.

## 4. Dependencies

The `pubspec.yaml` file lists all the packages the project depends on. Key dependencies include:
- `flutter`
- `google_fonts`
- `provider`
- `firebase_core`
- `firebase_ai`
- `go_router`
- `animated_text_kit`
- `flutter_markdown`
- `shared_preferences`

## 5. Current Plan

The current plan is to back up the project by creating a comprehensive blueprint of the existing code.
