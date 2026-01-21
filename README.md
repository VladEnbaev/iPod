# iPod Classic Clone (iOS)

A faithful recreation of the iconic iPod Classic first-generation interface built with modern iOS technologies.

![iOS](https://img.shields.io/badge/iOS-15+-blue.svg)
![TCA](https://img.shields.io/badge/Architecture-TCA-purple.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green.svg)

## 🎯 Overview

This project is a complete clone of the original iPod (1st Gen) interface, reimagined for modern iOS devices. It faithfully reproduces the iconic click wheel navigation, hierarchical menu system, and minimalist aesthetic of the 2001 classic, while leveraging contemporary development tools and architectural patterns.

<img width="400" height="866" alt="Снимок экрана 2025—12—25 в 13 49 14" src="https://github.com/user-attachments/assets/2beb3cfe-afb0-4e9f-8adc-ce7ab77bc1ac" />

## ✨ Features

### 🎵 **Core iPod Experience**
- **Click Wheel Emulation**: Gesture-based reproduction of the iconic physical wheel
- **Hierarchical Navigation**: Authentic tree-based menu system (Music → Artists → Albums → Songs)
- **Original UI Design**: Pixel-perfect recreation of the monochrome display and typography
- **iPod Controls**: Center button, Menu, Play/Pause, Next/Previous simulation

### 🎧 **Media Player**
- **Full Audio Playback**: Play, pause, seek, volume control
- **Media Library Integration**: Access to your device's music collection
- **Playback Modes**: Shuffle, repeat (one/all), queue management
- **Background Audio**: Continues playing when app is in background
- **Control Center**: Integration with iOS media controls

### 📱 **Modern iOS Integration**
- **The Composable Architecture**: Predictable state management
- **SwiftUI**: Declarative UI framework
- **Combine**: Reactive programming for events
- **MediaPlayer Framework**: System media library access
- **AVFoundation**: Professional audio playback

## 🛠️ Technologies

The application is built using a modern iOS development stack:

- **SwiftUI** – Declarative UI framework for building the interface
- **The Composable Architecture (TCA)** – State management with unidirectional data flow
- **AVFoundation** – Professional audio playback and media handling
- **MediaPlayer Framework** – Integration with system music library
- **Swift Concurrency** – async/await for asynchronous operations

The architecture follows a clean separation of concerns with distinct layers for UI, business logic, and data access.

## 📋 TODO / Roadmap

### 🔧 **Core Features to Implement**
- [ ] **Complete Player Screen**
- [ ] **Settings Screen**

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open in Xcode
3. Build and run on simulator or device

## 📄 License

This project is available under the MIT license.

- Apple Inc. for the original iPod design
- Point-Free for The Composable Architecture
- The Swift community for excellent tools and resources
