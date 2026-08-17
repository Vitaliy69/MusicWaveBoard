# 🎵 MusicWaveBoard

![Top language](https://img.shields.io/github/languages/top/Vitaliy69/MusicWaveBoard)
![Code size](https://img.shields.io/github/languages/code-size/Vitaliy69/MusicWaveBoard)
![Last commit](https://img.shields.io/github/last-commit/Vitaliy69/MusicWaveBoard)
![License](https://img.shields.io/github/license/Vitaliy69/MusicWaveBoard)

**MusicWaveBoard** is an iOS app that turns physical QR-coded chips into a musical instrument. The app scans QR codes on chips placed on a table using the front camera and automatically triggers corresponding audio loops. It supports up to 5–6 chips simultaneously, each with its own beat, individual volume, and smooth transitions.

## 🎬 Demo

- 📹 [App demo](https://www.youtube.com/watch?v=lSdb8hpyGrU)
- 📹 [Screen recording](https://www.youtube.com/watch?v=z-kaOTvW-gg)

## 🧩 How It Works

The app does not use Core ML or machine learning — chip recognition works through the built-in AVFoundation QR scanner (`AVCaptureMetadataOutput`). Each chip is simply a QR code containing a two-digit number.

1. The **front camera** captures the video stream and scans QR codes via `AVCaptureMetadataOutput`.
2. The search area is divided into **6 overlapping rectangles** that rotate every 0.2 s — this ensures full frame coverage and simultaneous detection of multiple chips.
3. When a QR code is detected, the app **smoothly fades in (1 s)** the corresponding audio loop via `AVAudioEngine`.
4. If a chip disappears from the frame for more than 2.5 s, the loop **smoothly fades out (1 s)**.
5. Each chip is displayed on screen as a card with an instrument icon and number.
6. Tapping a card lets you adjust **volume** or **mute** the track.
7. **Voice control** is available: long-press a sample in the list → speak a description → the app picks a matching loop by keywords.

## 🏗 Architecture

```
MusicWaveBoard/
├── AppDelegate.swift
├── Controllers/
│   ├── ViewController.swift         # Camera & QR detection
│   ├── QRObjects.swift              # Overlays, loop control
│   ├── SamplesViewController.swift  # Sample list + voice
│   ├── SampleTableViewCell.swift    # Sample cell
│   ├── RecordsViewController.swift  # (stub) Recordings
│   └── SettingsViewController.swift # (stub) Settings
├── Models/
│   └── LoopStorage.swift            # Voice search tags
├── Helpers/
│   ├── LoopPlayer.swift             # Audio engine + fade
│   ├── AVHelper.swift               # Audio session setup
│   ├── SampleManager.swift          # Keyword-based search
│   ├── SettingsManager.swift        # UserDefaults storage
│   └── SpeechRecognizer.swift       # Speech recognition
├── Views/
│   └── VolumeView.swift             # Volume slider
└── Assets.xcassets/
Samples/                             # 24 WAV files
```

## 📋 Classes

| Class | File | Description |
|---|---|---|
| `AppDelegate` | `AppDelegate.swift` | Standard app delegate |
| `ViewController` | `Controllers/ViewController.swift` | Sets up `AVCaptureSession` with the front camera, `AVCaptureMetadataOutputObjectsDelegate` for QR scanning |
| `QRObjects` | `Controllers/QRObjects.swift` | Subclass of `ViewController`. Draws overlays on camera (chip cards with instrument icons), manages loop on/off, handles taps (volume, mute), rotates 6 search regions |
| `SamplesViewController` | `Controllers/SamplesViewController.swift` | Table of 24 samples. Short tap — preview, long tap — voice input to assign a sample. Swipe — reset |
| `SampleTableViewCell` | `Controllers/SampleTableViewCell.swift` | Custom table cell: instrument icon, sample label, play button |
| `RecordsViewController` | `Controllers/RecordsViewController.swift` | Stub for recordings screen (not implemented) |
| `SettingsViewController` | `Controllers/SettingsViewController.swift` | Stub for settings screen (not implemented) |
| `LoopStorage` | `Models/LoopStorage.swift` | Static dictionary mapping 24 samples (`"01"`–`"24"`) to keyword arrays for voice search |
| `LoopPlayer` | `Helpers/LoopPlayer.swift` | Audio core: creates `AVAudioEngine` with 24 tracks (`AVAudioPlayerNode` + `AVAudioUnitEQ`), loops WAV files, manages fade-in/fade-out (1 s), converts volume on a logarithmic scale |
| `Latch` | `Helpers/LoopPlayer.swift` | Helper flag class for controlling `scheduleFile` looping |
| `AVHelper` | `Helpers/AVHelper.swift` | Static method to configure `AVAudioSession` (category, mode, activation, speaker routing) |
| `SampleManager` | `Helpers/SampleManager.swift` | Matches samples by keywords from speech (best match against `LoopStorage.loopTags`). Returns instrument icon by range: 1–6 → Voc, 7–12 → Drum, 13–18 → Guit, 19+ → Key |
| `SampleTrack` | `Helpers/SettingsManager.swift` | `Codable` model: track name + keywords |
| `SettingsManager` | `Helpers/SettingsManager.swift` | Saves/reads track assignments and per-channel volume in `UserDefaults` |
| `SpeechRecognizer` | `Helpers/SpeechRecognizer.swift` | Wrapper around `SFSpeechRecognizer`: captures microphone audio, streams to recognizer, returns text via `voiceHandler` closure |
| `VolumeView` | `Views/VolumeView.swift` | Pop-up `UISlider` for adjusting a specific track's volume with show/hide animation |

## 🔊 Samples

The `Samples/` folder contains **24 WAV files** (`01.wav`–`24.wav`) — generated spoken numbers ("one", "two", ..., "twenty-four") used as placeholder loops for demonstration. Each file corresponds to one mixer track and one QR chip.

You can replace these placeholder files with your own audio loops (WAV, 16-bit, 44100 Hz) to use the app with real beats.

Instrument categories (by icons):

| Range | Instrument | Icon |
|---|---|---|
| 01–06 | Vocals | `Voc` |
| 07–12 | Drums | `Drum` |
| 13–18 | Guitar | `Guit` |
| 19–24 | Keys | `Key` |

## 🛠 Requirements

| Parameter | Value |
|---|---|
| **Xcode** | 14.0+ |
| **iOS** | 13.0+ |
| **Swift** | 5.0 |
| **Device** | iPhone / iPad (arm64) |
| **Camera** | Front-facing (required) |
| **Microphone** | For voice control (optional) |
| **Speech Recognition** | Requires permission (optional) |
| **Dependencies** | None (system frameworks only) |

## 🔨 Build

1. Clone the repository:
   ```bash
   git clone https://github.com/Vitaliy69/MusicWaveBoard.git
   ```
2. Open `MusicWaveBoard.xcodeproj` in Xcode.
3. Select a target device (a real iPhone/iPad — the camera doesn't work in the simulator).
4. Press **⌘R** (Run).

> ⚠️ QR scanning requires a **real device** with a front camera. The simulator does not support video capture.

## 🎮 Usage

1. **Create chips** — print QR codes containing `"01"`, `"02"`, ..., `"24"` (track numbers).
2. Point the front camera at a chip — the corresponding loop starts playing.
3. Remove the chip — after 2.5 s the loop smoothly fades out.
4. **Tap a card** on screen → menu with volume adjustment and mute.
5. **Samples** tab → short tap to preview, long tap for voice sample assignment.

## 🏷 Creating QR Codes for Chips

Each chip is a regular QR code containing **only a two-digit track number** (from `01` to `24`). No URLs, prefixes, or quotes — just the number.

### QR Code Content Format

| QR Code | Content | What Plays |
|---|---|---|
| ![](https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=01) | `01` | Track 1 |
| ![](https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=02) | `02` | Track 2 |
| ... | ... | ... |
| ![](https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=24) | `24` | Track 24 |

### How to Generate QR Codes

**Online** (quickest way):

1. Open [https://www.qr-code-generator.com](https://www.qr-code-generator.com) or [https://api.qrserver.com](https://api.qrserver.com)
2. Select the "Text" type
3. Enter the track number: `01`, `02`, `03`, etc.
4. Download and print

**Via terminal** (macOS / Linux with Python):

```bash
pip install qrcode[pil]
python -c "import qrcode; [qrcode.make(f'{i:02d}').save(f'chip_{i:02d}.png') for i in range(1, 25)]"
```

This creates 24 files `chip_01.png` … `chip_24.png` — print them out and cut.

### Important Notes

- Numbers must be **two-digit**: `01`, not `1` — the format is `%.2d`.
- Available track range: **01–24** (exactly 24 mixer slots).
- Before using chips, you need to **assign samples** to tracks — **Samples** tab → long tap → voice input. Without an assigned sample, a track will be silent.
- QR code size on a chip should be at least ~2 cm for reliable scanning at arm's length.

## 📝 Notes

- `RecordsViewController` and `SettingsViewController` are stubs — functionality not yet implemented.
- The camera deliberately uses the **front-facing** camera — the app is designed for the user to see chips on a table in front of them.
- QR scanning uses rotation of 6 search regions (`searchRects`) — a trade-off between coverage and performance.
- Tracks 01–24 do not play out of the box — you must assign samples first via the **Samples** tab (voice input). `LoopPlayer` only loads tracks that have an assignment in `SettingsManager`.
- The project has 24 WAV loops — one per mixer track. You can replace them with your own audio files.

## 📄 License

The source code is licensed under the **MIT** license — see [LICENSE](LICENSE).

The concept, design, and idea of the app belong to the project author (Vitaliy Gribko). Use of the idea, as well as filing patent applications based on this solution, **is not permitted without the author's consent**.
