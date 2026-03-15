import 'package:flutter/material.dart';
import '../../models/chess_piece.dart';
import '../../models/game_state.dart';
import '../../logic/board_manager.dart';
import '../piece_renderer.dart';

class GameHudOverlay extends StatefulWidget {
  final BoardManager boardManager;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const GameHudOverlay({
    super.key,
    required this.boardManager,
    required this.onUndo,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  State<GameHudOverlay> createState() => _GameHudOverlayState();
}

class _GameHudOverlayState extends State<GameHudOverlay> {
  @override
  void initState() {
    super.initState();
    widget.boardManager.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.boardManager.state;

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          _buildTopBar(state),
          const Spacer(),
          // Bottom bar
          _buildBottomBar(state),
        ],
      ),
    );
  }

  Widget _buildTopBar(GameState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Back button
          _HudIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Menu',
            onPressed: widget.onMenu,
          ),
          const SizedBox(width: 8),

          // Black captured pieces
          Expanded(
            child: _CapturedPiecesRow(
              pieces: state.capturedBlack,
              label: 'Black captured',
            ),
          ),

          // Turn indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: state.currentTurn == PieceColor.white
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFF333340),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.status == GameStatus.check
                    ? const Color(0xFFCC2222)
                    : Colors.white24,
                width: state.status == GameStatus.check ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.currentTurn == PieceColor.white
                        ? Colors.white
                        : Colors.black,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.currentTurn == PieceColor.white ? 'W' : 'B',
                  style: TextStyle(
                    color: state.currentTurn == PieceColor.white
                        ? Colors.black87
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(GameState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // White captured pieces
          Expanded(
            child: _CapturedPiecesRow(
              pieces: state.capturedWhite,
              label: 'White captured',
            ),
          ),

          // Move counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Move ${state.fullMoveNumber}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),

          // Status text
          if (state.status == GameStatus.check)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x40CC2222),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'CHECK!',
                style: TextStyle(
                  color: Color(0xFFFF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Undo button
          _HudIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onPressed: state.moveHistory.isNotEmpty && !state.isGameOver
                ? widget.onUndo
                : null,
          ),
          const SizedBox(width: 4),

          // Restart button
          _HudIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart',
            onPressed: widget.onRestart,
          ),
        ],
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: onPressed != null
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.2),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _CapturedPiecesRow extends StatelessWidget {
  final List<ChessPiece> pieces;
  final String label;

  const _CapturedPiecesRow({required this.pieces, required this.label});

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) return const SizedBox.shrink();

    // Sort by value descending
    final sorted = List<ChessPiece>.from(pieces)
      ..sort((a, b) => b.materialValue.compareTo(a.materialValue));

    return SizedBox(
      height: 22,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        itemBuilder: (ctx, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 1),
            child: PieceRenderer.buildPieceWidget(sorted[i], 20),
          );
        },
      ),
    );
  }
}
