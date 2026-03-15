import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chess_piece.dart';

/// Renders chess pieces using Canvas drawing with stylized shapes and shadows.
class PieceRenderer {
  static void drawPiece(
    Canvas canvas,
    ChessPiece piece,
    Offset center,
    double size, {
    double opacity = 1.0,
    double scale = 1.0,
  }) {
    final adjustedSize = size * scale;
    final isWhite = piece.color == PieceColor.white;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      center + Offset(adjustedSize * 0.04, adjustedSize * 0.06),
      adjustedSize * 0.35,
      shadowPaint,
    );

    // Base colors
    final fillColor = isWhite
        ? Color.fromRGBO(255, 253, 240, opacity)
        : Color.fromRGBO(50, 50, 55, opacity);
    final outlineColor = isWhite
        ? Color.fromRGBO(80, 70, 60, opacity)
        : Color.fromRGBO(25, 25, 30, opacity);
    final accentColor = isWhite
        ? Color.fromRGBO(220, 210, 190, opacity)
        : Color.fromRGBO(90, 90, 100, opacity);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedSize * 0.04;
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    switch (piece.type) {
      case PieceType.king:
        _drawKing(canvas, center, adjustedSize, fillPaint, outlinePaint, accentPaint);
      case PieceType.queen:
        _drawQueen(canvas, center, adjustedSize, fillPaint, outlinePaint, accentPaint);
      case PieceType.rook:
        _drawRook(canvas, center, adjustedSize, fillPaint, outlinePaint, accentPaint);
      case PieceType.bishop:
        _drawBishop(canvas, center, adjustedSize, fillPaint, outlinePaint, accentPaint);
      case PieceType.knight:
        _drawKnight(canvas, center, adjustedSize, fillPaint, outlinePaint, accentPaint);
      case PieceType.pawn:
        _drawPawn(canvas, center, adjustedSize, fillPaint, outlinePaint, accentPaint);
    }
  }

  static void _drawKing(Canvas canvas, Offset c, double s, Paint fill, Paint outline, Paint accent) {
    final base = s * 0.38;

    // Body
    final bodyPath = Path()
      ..moveTo(c.dx - base * 0.55, c.dy + base * 0.5)
      ..lineTo(c.dx - base * 0.45, c.dy - base * 0.2)
      ..quadraticBezierTo(c.dx - base * 0.3, c.dy - base * 0.6, c.dx, c.dy - base * 0.5)
      ..quadraticBezierTo(c.dx + base * 0.3, c.dy - base * 0.6, c.dx + base * 0.45, c.dy - base * 0.2)
      ..lineTo(c.dx + base * 0.55, c.dy + base * 0.5)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, outline);

    // Cross on top
    final crossH = base * 0.25;
    final crossW = base * 0.08;
    final crossTop = c.dy - base * 0.85;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, crossTop + crossH * 0.5), width: crossW, height: crossH),
      fill,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, crossTop + crossH * 0.5), width: crossW, height: crossH),
      outline,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, crossTop + crossH * 0.2), width: crossH * 0.7, height: crossW),
      fill,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, crossTop + crossH * 0.2), width: crossH * 0.7, height: crossW),
      outline,
    );

    // Base platform
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.3, height: base * 0.2),
        Radius.circular(base * 0.05),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.3, height: base * 0.2),
        Radius.circular(base * 0.05),
      ),
      outline,
    );

    // Accent band
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.1), width: base * 0.7, height: base * 0.08),
      accent,
    );
  }

  static void _drawQueen(Canvas canvas, Offset c, double s, Paint fill, Paint outline, Paint accent) {
    final base = s * 0.38;

    // Body
    final bodyPath = Path()
      ..moveTo(c.dx - base * 0.55, c.dy + base * 0.5)
      ..lineTo(c.dx - base * 0.4, c.dy - base * 0.3)
      ..lineTo(c.dx - base * 0.55, c.dy - base * 0.65)
      ..lineTo(c.dx - base * 0.2, c.dy - base * 0.35)
      ..lineTo(c.dx, c.dy - base * 0.75)
      ..lineTo(c.dx + base * 0.2, c.dy - base * 0.35)
      ..lineTo(c.dx + base * 0.55, c.dy - base * 0.65)
      ..lineTo(c.dx + base * 0.4, c.dy - base * 0.3)
      ..lineTo(c.dx + base * 0.55, c.dy + base * 0.5)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, outline);

    // Crown jewels (small circles at tips)
    final jewel = Paint()..color = accent.color;
    canvas.drawCircle(Offset(c.dx - base * 0.55, c.dy - base * 0.65), base * 0.06, jewel);
    canvas.drawCircle(Offset(c.dx, c.dy - base * 0.75), base * 0.06, jewel);
    canvas.drawCircle(Offset(c.dx + base * 0.55, c.dy - base * 0.65), base * 0.06, jewel);

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.3, height: base * 0.2),
        Radius.circular(base * 0.05),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.3, height: base * 0.2),
        Radius.circular(base * 0.05),
      ),
      outline,
    );
  }

  static void _drawRook(Canvas canvas, Offset c, double s, Paint fill, Paint outline, Paint accent) {
    final base = s * 0.36;

    // Body
    final bodyPath = Path()
      ..moveTo(c.dx - base * 0.5, c.dy + base * 0.5)
      ..lineTo(c.dx - base * 0.45, c.dy - base * 0.2)
      ..lineTo(c.dx - base * 0.5, c.dy - base * 0.2)
      ..lineTo(c.dx - base * 0.5, c.dy - base * 0.55)
      ..lineTo(c.dx - base * 0.3, c.dy - base * 0.55)
      ..lineTo(c.dx - base * 0.3, c.dy - base * 0.35)
      ..lineTo(c.dx - base * 0.1, c.dy - base * 0.35)
      ..lineTo(c.dx - base * 0.1, c.dy - base * 0.55)
      ..lineTo(c.dx + base * 0.1, c.dy - base * 0.55)
      ..lineTo(c.dx + base * 0.1, c.dy - base * 0.35)
      ..lineTo(c.dx + base * 0.3, c.dy - base * 0.35)
      ..lineTo(c.dx + base * 0.3, c.dy - base * 0.55)
      ..lineTo(c.dx + base * 0.5, c.dy - base * 0.55)
      ..lineTo(c.dx + base * 0.5, c.dy - base * 0.2)
      ..lineTo(c.dx + base * 0.45, c.dy - base * 0.2)
      ..lineTo(c.dx + base * 0.5, c.dy + base * 0.5)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, outline);

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.2, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.2, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      outline,
    );

    // Accent band
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.15), width: base * 0.75, height: base * 0.07),
      accent,
    );
  }

  static void _drawBishop(Canvas canvas, Offset c, double s, Paint fill, Paint outline, Paint accent) {
    final base = s * 0.36;

    // Body — tall mitre shape
    final bodyPath = Path()
      ..moveTo(c.dx - base * 0.45, c.dy + base * 0.5)
      ..lineTo(c.dx - base * 0.3, c.dy - base * 0.1)
      ..quadraticBezierTo(c.dx - base * 0.35, c.dy - base * 0.5, c.dx, c.dy - base * 0.75)
      ..quadraticBezierTo(c.dx + base * 0.35, c.dy - base * 0.5, c.dx + base * 0.3, c.dy - base * 0.1)
      ..lineTo(c.dx + base * 0.45, c.dy + base * 0.5)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, outline);

    // Diagonal slit on the mitre
    final slitPaint = Paint()
      ..color = outline.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = base * 0.03;
    canvas.drawLine(
      Offset(c.dx - base * 0.12, c.dy - base * 0.15),
      Offset(c.dx + base * 0.08, c.dy - base * 0.5),
      slitPaint,
    );

    // Tip ball
    canvas.drawCircle(Offset(c.dx, c.dy - base * 0.78), base * 0.07, fill);
    canvas.drawCircle(Offset(c.dx, c.dy - base * 0.78), base * 0.07, outline);

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.15, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.15, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      outline,
    );
  }

  static void _drawKnight(Canvas canvas, Offset c, double s, Paint fill, Paint outline, Paint accent) {
    final base = s * 0.38;

    // Horse head shape
    final bodyPath = Path()
      ..moveTo(c.dx - base * 0.35, c.dy + base * 0.5)
      ..lineTo(c.dx - base * 0.3, c.dy)
      ..quadraticBezierTo(c.dx - base * 0.55, c.dy - base * 0.3, c.dx - base * 0.25, c.dy - base * 0.55)
      ..quadraticBezierTo(c.dx - base * 0.1, c.dy - base * 0.75, c.dx + base * 0.05, c.dy - base * 0.7)
      ..lineTo(c.dx + base * 0.15, c.dy - base * 0.6)
      ..quadraticBezierTo(c.dx + base * 0.4, c.dy - base * 0.55, c.dx + base * 0.35, c.dy - base * 0.3)
      ..quadraticBezierTo(c.dx + base * 0.3, c.dy - base * 0.1, c.dx + base * 0.4, c.dy + base * 0.1)
      ..lineTo(c.dx + base * 0.45, c.dy + base * 0.5)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, outline);

    // Eye
    final eyePaint = Paint()..color = outline.color;
    canvas.drawCircle(Offset(c.dx + base * 0.05, c.dy - base * 0.4), base * 0.05, eyePaint);

    // Nostril
    canvas.drawCircle(Offset(c.dx + base * 0.25, c.dy - base * 0.2), base * 0.03, eyePaint);

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.2, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.55), width: base * 1.2, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      outline,
    );
  }

  static void _drawPawn(Canvas canvas, Offset c, double s, Paint fill, Paint outline, Paint accent) {
    final base = s * 0.32;

    // Head (circle)
    canvas.drawCircle(Offset(c.dx, c.dy - base * 0.4), base * 0.28, fill);
    canvas.drawCircle(Offset(c.dx, c.dy - base * 0.4), base * 0.28, outline);

    // Neck/body taper
    final bodyPath = Path()
      ..moveTo(c.dx - base * 0.4, c.dy + base * 0.45)
      ..quadraticBezierTo(c.dx - base * 0.15, c.dy + base * 0.05, c.dx - base * 0.15, c.dy - base * 0.15)
      ..lineTo(c.dx + base * 0.15, c.dy - base * 0.15)
      ..quadraticBezierTo(c.dx + base * 0.15, c.dy + base * 0.05, c.dx + base * 0.4, c.dy + base * 0.45)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, outline);

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.5), width: base * 1.0, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + base * 0.5), width: base * 1.0, height: base * 0.18),
        Radius.circular(base * 0.05),
      ),
      outline,
    );
  }

  /// Draw a small piece icon for HUD/promotion dialogs.
  static Widget buildPieceWidget(ChessPiece piece, double size) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PiecePainter(piece),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final ChessPiece piece;
  _PiecePainter(this.piece);

  @override
  void paint(Canvas canvas, Size size) {
    PieceRenderer.drawPiece(
      canvas,
      piece,
      Offset(size.width / 2, size.height / 2),
      size.width,
    );
  }

  @override
  bool shouldRepaint(_PiecePainter old) => old.piece != piece;
}
