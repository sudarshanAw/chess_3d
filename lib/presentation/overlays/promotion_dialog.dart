import 'package:flutter/material.dart';
import '../../models/chess_piece.dart';
import '../piece_renderer.dart';

class PromotionDialog extends StatelessWidget {
  final PieceColor color;

  const PromotionDialog({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final options = [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ];

    return Dialog(
      backgroundColor: const Color(0xFF1A1A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Promote Pawn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a piece',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: options.map((type) {
                final piece = ChessPiece(type: type, color: color);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _PromotionOption(
                    piece: piece,
                    label: type.name[0].toUpperCase() + type.name.substring(1),
                    onTap: () => Navigator.pop(context, type),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionOption extends StatefulWidget {
  final ChessPiece piece;
  final String label;
  final VoidCallback onTap;

  const _PromotionOption({
    required this.piece,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PromotionOption> createState() => _PromotionOptionState();
}

class _PromotionOptionState extends State<_PromotionOption> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovering
                ? const Color(0xFF3A3A5E)
                : const Color(0xFF2A2A4E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovering ? const Color(0xFFFFD700) : Colors.white24,
              width: _hovering ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PieceRenderer.buildPieceWidget(widget.piece, 48),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
