import 'package:flutter/material.dart';
import '../../models/chess_piece.dart';
import '../../models/game_state.dart';
import '../../logic/board_manager.dart';

class GameOverOverlay extends StatelessWidget {
  final BoardManager boardManager;
  final VoidCallback onNewGame;
  final VoidCallback onMenu;

  const GameOverOverlay({
    super.key,
    required this.boardManager,
    required this.onNewGame,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final state = boardManager.state;
    final isCheckmate = state.status == GameStatus.checkmate;
    final isDraw = !isCheckmate;

    String title;
    String subtitle;
    Color accentColor;

    if (isCheckmate) {
      final winner =
          state.currentTurn == PieceColor.white ? 'Black' : 'White';
      title = '$winner Wins!';
      subtitle = 'Checkmate';
      accentColor = const Color(0xFFFFD700);
    } else {
      title = 'Draw';
      switch (state.status) {
        case GameStatus.stalemate:
          subtitle = 'Stalemate - No legal moves';
        case GameStatus.drawInsufficient:
          subtitle = 'Insufficient material';
        case GameStatus.drawFiftyMove:
          subtitle = 'Fifty-move rule';
        case GameStatus.drawRepetition:
          subtitle = 'Threefold repetition';
        default:
          subtitle = 'Game drawn';
      }
      accentColor = const Color(0xFF87CEEB);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xF01A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy/draw icon
            Icon(
              isCheckmate ? Icons.emoji_events_rounded : Icons.handshake_rounded,
              size: 56,
              color: accentColor,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),

            // Move count
            Text(
              '${state.moveHistory.length} moves played',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: onNewGame,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('New Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: onMenu,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Menu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
