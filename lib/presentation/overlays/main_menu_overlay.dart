import 'package:flutter/material.dart';

class MainMenuOverlay extends StatelessWidget {
  final VoidCallback onNewGame;

  const MainMenuOverlay({super.key, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0F23), Color(0xFF1A1A3E), Color(0xFF16213E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
              ).createShader(bounds),
              child: const Text(
                'Chess 3D',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: Color(0x80000000), offset: Offset(2, 3), blurRadius: 6),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A Classic Game of Strategy',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 2,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 60),

            // Chess piece decorative row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final symbol in ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),

            // New Game button
            _MenuButton(
              label: 'New Game',
              icon: Icons.play_arrow_rounded,
              onPressed: onNewGame,
              primary: true,
            ),
            const SizedBox(height: 16),

            // How to Play button
            _MenuButton(
              label: 'How to Play',
              icon: Icons.help_outline_rounded,
              onPressed: () => _showHowToPlay(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3E),
        title: const Text(
          'How to Play',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '• Tap a piece to select it\n'
            '• Green dots show valid moves\n'
            '• Red corners show captures\n'
            '• Tap a valid square to move\n\n'
            'Special Moves:\n'
            '• Castling: Move king two squares toward a rook\n'
            '• En passant: Capture a pawn that just moved two squares\n'
            '• Promotion: A pawn reaching the last rank promotes\n\n'
            'Game Ends:\n'
            '• Checkmate: King is in check with no escape\n'
            '• Stalemate: No legal moves but not in check (draw)\n'
            '• Draw by insufficient material, 50-move rule, or threefold repetition',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? const Color(0xFFFFD700) : const Color(0xFF2A2A4E),
          foregroundColor: primary ? const Color(0xFF1A1A2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: primary ? 6 : 2,
        ),
      ),
    );
  }
}
