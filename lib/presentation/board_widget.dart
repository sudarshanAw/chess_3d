import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chess_piece.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';
import '../logic/board_manager.dart';
import 'piece_renderer.dart';

/// The main chess board widget with 3D perspective transform and all visual effects.
class BoardWidget extends StatefulWidget {
  final BoardManager boardManager;

  const BoardWidget({super.key, required this.boardManager});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> with TickerProviderStateMixin {
  late AnimationController _moveAnimController;
  late AnimationController _selectionPulseController;
  late AnimationController _checkPulseController;

  // Move animation state
  BoardPosition? _animFrom;
  BoardPosition? _animTo;
  ChessPiece? _animPiece;
  bool _isAnimatingMove = false;

  @override
  void initState() {
    super.initState();
    _moveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectionPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _checkPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    widget.boardManager.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _moveAnimController.dispose();
    _selectionPulseController.dispose();
    _checkPulseController.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPosition, double boardSize, double squareSize, Offset boardOrigin) {
    final state = widget.boardManager.state;
    if (state.isGameOver || _isAnimatingMove) return;

    // Convert tap position to board coordinates
    final relX = localPosition.dx - boardOrigin.dx;
    final relY = localPosition.dy - boardOrigin.dy;

    if (relX < 0 || relY < 0 || relX >= boardSize || relY >= boardSize) return;

    final col = (relX / squareSize).floor().clamp(0, 7);
    final row = (relY / squareSize).floor().clamp(0, 7);
    final pos = BoardPosition(row, col);

    // Animate if this is a move
    if (state.selectedPosition != null && state.validMoves.contains(pos)) {
      _animateMove(state.selectedPosition!, pos, state.board[state.selectedPosition!.row][state.selectedPosition!.col]!);
    } else {
      widget.boardManager.onSquareTapped(pos);
    }
  }

  Future<void> _animateMove(BoardPosition from, BoardPosition to, ChessPiece piece) async {
    setState(() {
      _animFrom = from;
      _animTo = to;
      _animPiece = piece;
      _isAnimatingMove = true;
    });
    _moveAnimController.reset();
    await _moveAnimController.forward();
    setState(() {
      _isAnimatingMove = false;
      _animFrom = null;
      _animTo = null;
      _animPiece = null;
    });
    await widget.boardManager.onSquareTapped(to);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        // Board takes up most of the width, leaving some margin
        final boardSize = min(availableWidth * 0.92, availableHeight * 0.75);
        final squareSize = boardSize / 8;

        return AnimatedBuilder(
          animation: Listenable.merge([_selectionPulseController, _checkPulseController, _moveAnimController]),
          builder: (context, child) {
            return GestureDetector(
              onTapUp: (details) {
                // Calculate where the board is drawn within the transformed space
                final boardOrigin = Offset(
                  (availableWidth - boardSize) / 2,
                  (availableHeight - boardSize) / 2 + boardSize * 0.05,
                );
                _handleTap(details.localPosition, boardSize, squareSize, boardOrigin);
              },
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008) // perspective
                  ..rotateX(0.45), // ~25 degree tilt
                child: CustomPaint(
                  size: Size(availableWidth, availableHeight),
                  painter: _BoardPainter(
                    state: widget.boardManager.state,
                    boardSize: boardSize,
                    squareSize: squareSize,
                    boardOrigin: Offset(
                      (availableWidth - boardSize) / 2,
                      (availableHeight - boardSize) / 2 + boardSize * 0.05,
                    ),
                    selectionPulse: _selectionPulseController.value,
                    checkPulse: _checkPulseController.value,
                    moveAnimValue: _moveAnimController.value,
                    animFrom: _animFrom,
                    animTo: _animTo,
                    animPiece: _animPiece,
                    isAnimating: _isAnimatingMove,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final GameState state;
  final double boardSize;
  final double squareSize;
  final Offset boardOrigin;
  final double selectionPulse;
  final double checkPulse;
  final double moveAnimValue;
  final BoardPosition? animFrom;
  final BoardPosition? animTo;
  final ChessPiece? animPiece;
  final bool isAnimating;

  static const lightSquare = Color(0xFFF0D9B5);
  static const darkSquare = Color(0xFFB58863);
  static const selectedColor = Color(0xFFFFD700);
  static const validMoveColor = Color(0x6044CC44);
  static const captureColor = Color(0x60CC4444);
  static const checkColor = Color(0xFFCC2222);

  _BoardPainter({
    required this.state,
    required this.boardSize,
    required this.squareSize,
    required this.boardOrigin,
    required this.selectionPulse,
    required this.checkPulse,
    required this.moveAnimValue,
    this.animFrom,
    this.animTo,
    this.animPiece,
    required this.isAnimating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoardShadow(canvas);
    _drawBoard(canvas);
    _drawHighlights(canvas);
    _drawPieces(canvas);
    _drawMoveAnimation(canvas);
    _drawFileRankLabels(canvas);
  }

  void _drawBoardShadow(Canvas canvas) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          boardOrigin.dx - 4,
          boardOrigin.dy - 4,
          boardSize + 8,
          boardSize + 8,
        ),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    // Board edge (3D depth effect)
    final edgePaint = Paint()..color = const Color(0xFF8B7355);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          boardOrigin.dx - 3,
          boardOrigin.dy - 3,
          boardSize + 6,
          boardSize + 6,
        ),
        const Radius.circular(3),
      ),
      edgePaint,
    );
  }

  void _drawBoard(Canvas canvas) {
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final isLight = (row + col) % 2 == 0;
        final baseColor = isLight ? lightSquare : darkSquare;

        // Subtle gradient for 3D depth
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, Colors.white, 0.05)!,
              Color.lerp(baseColor, Colors.black, 0.05)!,
            ],
          ).createShader(Rect.fromLTWH(
            boardOrigin.dx + col * squareSize,
            boardOrigin.dy + row * squareSize,
            squareSize,
            squareSize,
          ));

        canvas.drawRect(
          Rect.fromLTWH(
            boardOrigin.dx + col * squareSize,
            boardOrigin.dy + row * squareSize,
            squareSize,
            squareSize,
          ),
          paint,
        );
      }
    }
  }

  void _drawHighlights(Canvas canvas) {
    // Selected square highlight
    if (state.selectedPosition != null) {
      final pos = state.selectedPosition!;
      final glow = 0.3 + selectionPulse * 0.3;
      final paint = Paint()..color = selectedColor.withValues(alpha: glow);
      canvas.drawRect(
        Rect.fromLTWH(
          boardOrigin.dx + pos.col * squareSize,
          boardOrigin.dy + pos.row * squareSize,
          squareSize,
          squareSize,
        ),
        paint,
      );

      // Selection border
      final borderPaint = Paint()
        ..color = selectedColor.withValues(alpha: 0.6 + selectionPulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(
        Rect.fromLTWH(
          boardOrigin.dx + pos.col * squareSize + 1,
          boardOrigin.dy + pos.row * squareSize + 1,
          squareSize - 2,
          squareSize - 2,
        ),
        borderPaint,
      );
    }

    // Valid move indicators
    for (final move in state.validMoves) {
      final cx = boardOrigin.dx + move.col * squareSize + squareSize / 2;
      final cy = boardOrigin.dy + move.row * squareSize + squareSize / 2;

      final targetPiece = state.board[move.row][move.col];
      final isEnPassantCapture = state.enPassantTarget != null && move == state.enPassantTarget;

      if (targetPiece != null || isEnPassantCapture) {
        // Capture indicator: corner triangles
        final capPaint = Paint()..color = captureColor;
        final triSize = squareSize * 0.22;
        final left = boardOrigin.dx + move.col * squareSize;
        final top = boardOrigin.dy + move.row * squareSize;
        final right = left + squareSize;
        final bottom = top + squareSize;

        for (final corner in [
          [left, top, left + triSize, top, left, top + triSize],
          [right, top, right - triSize, top, right, top + triSize],
          [left, bottom, left + triSize, bottom, left, bottom - triSize],
          [right, bottom, right - triSize, bottom, right, bottom - triSize],
        ]) {
          final path = Path()
            ..moveTo(corner[0], corner[1])
            ..lineTo(corner[2], corner[3])
            ..lineTo(corner[4], corner[5])
            ..close();
          canvas.drawPath(path, capPaint);
        }
      } else {
        // Move indicator: semi-transparent circle
        canvas.drawCircle(
          Offset(cx, cy),
          squareSize * 0.15,
          Paint()..color = validMoveColor,
        );
      }
    }

    // Check indicator
    if (state.kingInCheck != null) {
      final pos = state.kingInCheck!;
      final alpha = 0.25 + checkPulse * 0.35;
      final paint = Paint()..color = checkColor.withValues(alpha: alpha);
      canvas.drawRect(
        Rect.fromLTWH(
          boardOrigin.dx + pos.col * squareSize,
          boardOrigin.dy + pos.row * squareSize,
          squareSize,
          squareSize,
        ),
        paint,
      );
    }

    // Last move highlight
    if (state.moveHistory.isNotEmpty) {
      final lastMove = state.moveHistory.last;
      final hlPaint = Paint()..color = const Color(0x30FFFF00);
      for (final pos in [lastMove.from, lastMove.to]) {
        canvas.drawRect(
          Rect.fromLTWH(
            boardOrigin.dx + pos.col * squareSize,
            boardOrigin.dy + pos.row * squareSize,
            squareSize,
            squareSize,
          ),
          hlPaint,
        );
      }
    }
  }

  void _drawPieces(Canvas canvas) {
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = state.board[row][col];
        if (piece == null) continue;

        // Skip the animating piece at its origin
        if (isAnimating &&
            animFrom != null &&
            animFrom!.row == row &&
            animFrom!.col == col) {
          continue;
        }

        final center = Offset(
          boardOrigin.dx + col * squareSize + squareSize / 2,
          boardOrigin.dy + row * squareSize + squareSize / 2,
        );

        PieceRenderer.drawPiece(canvas, piece, center, squareSize * 0.95);
      }
    }
  }

  void _drawMoveAnimation(Canvas canvas) {
    if (!isAnimating || animFrom == null || animTo == null || animPiece == null) {
      return;
    }

    // Smooth ease-out interpolation
    final t = Curves.easeInOut.transform(moveAnimValue);

    final fromCenter = Offset(
      boardOrigin.dx + animFrom!.col * squareSize + squareSize / 2,
      boardOrigin.dy + animFrom!.row * squareSize + squareSize / 2,
    );
    final toCenter = Offset(
      boardOrigin.dx + animTo!.col * squareSize + squareSize / 2,
      boardOrigin.dy + animTo!.row * squareSize + squareSize / 2,
    );

    final currentPos = Offset.lerp(fromCenter, toCenter, t)!;

    // Slight bounce: scale up slightly in the middle, back to normal at end
    final bounceScale = 1.0 + 0.08 * sin(t * pi);

    PieceRenderer.drawPiece(
      canvas,
      animPiece!,
      currentPos,
      squareSize * 0.95,
      scale: bounceScale,
    );
  }

  void _drawFileRankLabels(Canvas canvas) {
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: squareSize * 0.18,
      fontWeight: FontWeight.w500,
    );

    for (int col = 0; col < 8; col++) {
      final label = String.fromCharCode('a'.codeUnitAt(0) + col);
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          boardOrigin.dx + col * squareSize + squareSize / 2 - tp.width / 2,
          boardOrigin.dy + boardSize + 4,
        ),
      );
    }

    for (int row = 0; row < 8; row++) {
      final label = (8 - row).toString();
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          boardOrigin.dx - tp.width - 6,
          boardOrigin.dy + row * squareSize + squareSize / 2 - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
