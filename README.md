# M'ama Non M'ama 🌸

Un'applicazione Flutter che simula il classico gioco "m'ama non m'ama".

## Come funziona

1. L'app mostra un fiore con **13 petali**.
2. Premi **START** per avviare l'animazione (e la musica di sottofondo, se disponibile).
3. I petali cadono uno alla volta con un'animazione fluida (gravità + rotazione + dissolvenza).
4. Per ogni petalo viene mostrato alternatamente **"M'AMA"** o **"NON M'AMA"**.
5. Quando tutti i petali sono caduti, appare il risultato finale.
6. Premi **Ricomincia** per giocare di nuovo.

## Getting Started

### Requisiti

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.3.0
- Dart ≥ 3.3.0

### Installazione

```bash
flutter pub get
flutter run
```

### Musica di sottofondo (opzionale)

Aggiungi un file MP3 royalty-free in `assets/audio/music.mp3`.  
L'app funziona anche senza il file audio.

## Struttura del progetto

```
lib/
  main.dart          # App, GameScreen, FlowerPainter
assets/
  audio/
    music.mp3        # (aggiungere manualmente)
test/
  widget_test.dart   # Widget test di base
```

## Dipendenze principali

| Pacchetto | Versione | Scopo |
|-----------|----------|-------|
| [audioplayers](https://pub.dev/packages/audioplayers) | ^6.1.0 | Musica di sottofondo |