# Chess 3D

A polished 2.5D/3D-like chess game built with Flutter and Flame. Features a perspective-transformed board, custom Canvas-drawn pieces, and complete chess rule implementation.

## Features

### Complete Chess Rules
- All 6 piece types with correct movement
- Castling (kingside and queenside) with full condition checking
- En passant capture
- Pawn promotion with piece selection dialog
- Check and checkmate detection
- Stalemate detection
- Draw by insufficient material (K vs K, K+B vs K, K+N vs K, K+B vs K+B same color)
- Draw by fifty-move rule
- Draw by threefold repetition

### Visual Polish
- **3D-like perspective board** using Matrix4 transforms
- **Custom Canvas-drawn pieces** with shadows and depth effects
- **Smooth move animations** with ease-in-out curves and subtle bounce
- **Selection highlights** with pulsing golden glow
- **Valid move indicators** (circles for moves, corner triangles for captures)
- **Check indicator** with red pulsing effect on king's square
- **Last move highlight** for tracking game flow

### UI
- **Main Menu** with elegant styling and how-to-play info
- **Game HUD** with turn indicator, captured pieces, move counter, and status
- **Game Over overlay** with result, reason, and action buttons
- **Promotion dialog** with visual piece selection
- **Undo move** functionality
- **Restart game** and return to menu

## Architecture

```
lib/
├── main.dart                      # App entry point
├── models/                        # Pure Dart data classes
│   ├── chess_piece.dart           # Piece type, color, state
│   ├── board_position.dart        # Board coordinates
│   ├── move.dart                  # Move representation
│   └── game_state.dart            # Complete game state
├── logic/                         # Chess engine (no Flutter deps)
│   ├── board_manager.dart         # Central game controller
│   ├── move_validator.dart        # Pseudo-legal move generation
│   ├── check_detector.dart        # Check/legal move filtering
│   └── game_rules.dart            # Draw detection rules
├── presentation/                  # UI and rendering
│   ├── chess_game.dart            # Flame game + widget setup
│   ├── board_widget.dart          # Board rendering with transforms
│   ├── piece_renderer.dart        # Canvas piece drawing
│   └── overlays/                  # UI overlays
│       ├── main_menu_overlay.dart
│       ├── game_hud_overlay.dart
│       ├── game_over_overlay.dart
│       └── promotion_dialog.dart
└── services/                      # Infrastructure services
    ├── asset_loader.dart          # Asset management
    └── audio_service.dart         # Sound management
```

## Setup

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+

### Run
```bash
flutter pub get
flutter run
```

### Build
```bash
flutter build apk
```

## Dependencies

- **flame** - Game engine container with overlay management
- **flutter_3d_controller** - Included for future 3D model integration

## Technical Details

- Board rendered with `CustomPainter` inside a `Transform` widget using `Matrix4` perspective
- All pieces drawn with Canvas API — no external image assets required
- Game logic is pure Dart, fully testable independently
- State management via streams from `BoardManager`
- Flame's `FlameGame` provides the game loop and overlay infrastructure

## License

MIT
