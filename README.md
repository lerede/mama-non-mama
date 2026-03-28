# M'ama Non M'ama 🌸

A Flutter application that simulates the classic Italian **"m'ama non m'ama"** (loves me, loves me not) game.

## Come si gioca / How to play

1. Press **Start** to begin the animation.
2. Watch the flower petals fall one by one with a smooth animation.
3. Each petal reveals **"M'ama..."** or **"Non m'ama..."** alternately.
4. When the last petal falls, the final answer is revealed.
5. Press **Riprova 🌸** to play again.

## Features

- 🌼 Hand-drawn daisy flower painted with Flutter's `CustomPainter`
- 🍃 Smooth petal-fall animations using `AnimationController` + `CurvedAnimation`
- 🎵 Background music via `audioplayers` (place `assets/music/background.mp3`)
- 📱 Runs on Android, iOS, and Web

## Getting started

```bash
flutter pub get
flutter run
```

### Background music

Place a royalty-free `.mp3` file at `assets/music/background.mp3`.
If the file is absent the app works silently.
