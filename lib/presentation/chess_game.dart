import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../logic/board_manager.dart';
import '../models/chess_piece.dart';
import 'board_widget.dart';
import 'overlays/main_menu_overlay.dart';
import 'overlays/game_hud_overlay.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/promotion_dialog.dart';

/// The main Flame game container. Uses overlays for all UI.
/// The board is rendered as a Flutter widget overlay for maximum control
/// over transforms and painting.
class ChessGame extends FlameGame {
  final BoardManager boardManager;

  ChessGame({required this.boardManager});

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    // Show main menu initially
    overlays.add('mainMenu');
  }

  void startGame() {
    boardManager.restart();
    overlays.remove('mainMenu');
    overlays.remove('gameOver');
    overlays.add('gameBoard');
    overlays.add('gameHud');
  }

  void showGameOver() {
    overlays.add('gameOver');
  }

  void returnToMenu() {
    overlays.remove('gameBoard');
    overlays.remove('gameHud');
    overlays.remove('gameOver');
    overlays.add('mainMenu');
  }
}

/// Builds the GameWidget with all overlays registered.
class ChessGameWidget extends StatefulWidget {
  const ChessGameWidget({super.key});

  @override
  State<ChessGameWidget> createState() => _ChessGameWidgetState();
}

class _ChessGameWidgetState extends State<ChessGameWidget> {
  late final BoardManager _boardManager;
  late final ChessGame _game;

  @override
  void initState() {
    super.initState();
    _boardManager = BoardManager();
    _game = ChessGame(boardManager: _boardManager);

    // Set up promotion callback
    _boardManager.onPromotionRequired = _showPromotionDialog;

    // Listen for game-over events
    _boardManager.stateStream.listen((state) {
      if (state.isGameOver && !_game.overlays.isActive('gameOver')) {
        _game.showGameOver();
      }
    });
  }

  Future<PieceType> _showPromotionDialog() async {
    final result = await showDialog<PieceType>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PromotionDialog(
        color: _boardManager.state.currentTurn,
      ),
    );
    return result ?? PieceType.queen;
  }

  @override
  void dispose() {
    _boardManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: _game,
      overlayBuilderMap: {
        'mainMenu': (context, game) => MainMenuOverlay(
              onNewGame: () => _game.startGame(),
            ),
        'gameBoard': (context, game) => Positioned.fill(
              child: BoardWidget(boardManager: _boardManager),
            ),
        'gameHud': (context, game) => GameHudOverlay(
              boardManager: _boardManager,
              onUndo: () => _boardManager.undoLastMove(),
              onRestart: () => _game.startGame(),
              onMenu: () => _game.returnToMenu(),
            ),
        'gameOver': (context, game) => GameOverOverlay(
              boardManager: _boardManager,
              onNewGame: () => _game.startGame(),
              onMenu: () => _game.returnToMenu(),
            ),
      },
    );
  }
}
