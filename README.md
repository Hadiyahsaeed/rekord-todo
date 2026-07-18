# todo

This project represents a full-stack application template leveraging a suite of Firebase services for modern web and mobile development. It integrates powerful Generative AI capabilities via Firebase AI Logic (Gemini API), provides robust user authentication, and utilizes Firebase App Hosting for scalable and efficient deployment of web applications.

## Features

*   **Generative AI Integration**: Direct client-side access to Gemini models for AI-powered features across web, Android, iOS, and Flutter platforms.
*   **Robust User Authentication**: Secure user management and authentication powered by Firebase Authentication.
*   **Full-Stack Web Hosting**: Seamless deployment and management of modern web applications (e.g., Next.js, Angular) with Firebase App Hosting.
*   **CLI-First Development**: Efficient backend provisioning and service management using the Firebase Command Line Interface.
*   **Local Development & Emulation**: Test App Hosting configurations and app behavior locally with the Firebase Emulator Suite before deployment.
*   **Cross-Platform Support**: Includes setup guides and usage patterns for Web (JavaScript), Android (Kotlin), iOS (Swift), and Flutter (Dart).

## Installation

To get started with this project, you'll need the Firebase CLI and to initialize your Firebase project.

1.  **Install Firebase CLI**:
    Ensure you have the Firebase CLI installed globally or use `npx` for specific commands.

    ```bash
    npm install -g firebase-tools
    ```

2.  **Initialize Firebase Project**:
    Navigate to your project's root directory and initialize Firebase. During this interactive process, select the services you intend to use (e.g., AI Logic, Authentication, App Hosting).

    ```bash
    firebase init
    ```

    Alternatively, you can initialize specific services:

    *   **AI Logic (Gemini API)**:
        ```bash
        npx -y firebase-tools@latest init # When prompted, select 'AI logic'
        ```
    *   **Authentication**:
        ```bash
        npx -y firebase-tools@latest init auth
        ```
    *   **App Hosting**:
        ```bash
        npx -y firebase-tools@latest init apphosting
        ```

3.  **Add Platform-Specific SDKs**:
    Refer to the respective setup guides in the `.agents/skills` directory for detailed instructions on adding Firebase SDKs to your chosen client application (Web, Android, iOS, or Flutter).

## Usage

Once installed and configured, you can begin developing your application leveraging Firebase services.

1.  **Initialize Firebase App**:
    Ensure the main Firebase application is initialized in your client-side code before using any specific Firebase service.

    ```javascript
    // Web example
    import { initializeApp } from "firebase/app";
    const firebaseConfig = { /* ... your firebase config ... */ };
    const app = initializeApp(firebaseConfig);
    ```

2.  **Utilize Firebase AI Logic**:
    Access generative models. Remember to replace `<latest_supported_model>` with an actual model name (refer to Firebase documentation for available models).

    ```swift
    // iOS example
    import FirebaseAILogic
    let ai = FirebaseAI.firebaseAI()
    let model = ai.generativeModel(modelName: "<latest_supported_model>")
    ```

    ```javascript
    // Web example
    import { getAI, getGenerativeModel } from "firebase/ai";
    const ai = getAI(app);
    const model = getGenerativeModel(ai, "<latest_supported_model>");
    ```

3.  **Configure App Hosting**:
    Define your backend's configuration and environment variables in the `apphosting.yaml` file located in your app's root directory. For local testing, use `apphosting.emulator.yaml` to override settings or provide local secret values.

    ```yaml
    # apphosting.yaml example
    runConfig:
      cpu: 1
      memoryMiB: 512
      minInstances: 0
      maxInstances: 100
      concurrency: 80
    env:
      - variable: STORAGE_BUCKET
    ```

4.  **Deploy**:
    After configuring your application, use Firebase CLI commands to deploy your web application and associated backend services.

## Tech Stack

*   **Platform**: Google Firebase
    *   Firebase AI Logic (Gemini API)
    *   Firebase App Hosting
    *   Firebase Authentication
*   **Supported Client Platforms**:
    *   Web (JavaScript)
    *   Android (Kotlin)
    *   iOS (Swift)
    *   Flutter (Dart)
*   **Supported Web Frameworks (via App Hosting)**:
    *   Next.js
    *   Angular
*   **Tooling**:
    *   Firebase CLI
    *   Swift Package Manager