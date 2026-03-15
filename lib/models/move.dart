import 'board_position.dart';
import 'chess_piece.dart';

enum MoveType { normal, capture, castleKingside, castleQueenside, enPassant, promotion }

class ChessMove {
  final BoardPosition from;
  final BoardPosition to;
  final ChessPiece piece;
  final ChessPiece? capturedPiece;
  final MoveType moveType;
  final PieceType? promotionType;
  // Snapshot for undo: the entire board state before this move
  final List<List<ChessPiece?>>? boardBefore;
  final BoardPosition? enPassantTargetBefore;
  final int halfMoveClockBefore;

  const ChessMove({
    required this.from,
    required this.to,
    required this.piece,
    this.capturedPiece,
    this.moveType = MoveType.normal,
    this.promotionType,
    this.boardBefore,
    this.enPassantTargetBefore,
    this.halfMoveClockBefore = 0,
  });

  bool get isCapture =>
      moveType == MoveType.capture || moveType == MoveType.enPassant;

  bool get isCastle =>
      moveType == MoveType.castleKingside ||
      moveType == MoveType.castleQueenside;

  bool get isPromotion => moveType == MoveType.promotion;

  String get notation {
    if (moveType == MoveType.castleKingside) return 'O-O';
    if (moveType == MoveType.castleQueenside) return 'O-O-O';

    final buffer = StringBuffer();
    if (piece.type != PieceType.pawn) {
      buffer.write(piece.type.name[0].toUpperCase());
      if (piece.type == PieceType.knight) buffer.clear();
      if (piece.type == PieceType.knight) buffer.write('N');
    }
    if (isCapture) {
      if (piece.type == PieceType.pawn) {
        buffer.write(from.algebraic[0]);
      }
      buffer.write('x');
    }
    buffer.write(to.algebraic);
    if (isPromotion && promotionType != null) {
      buffer.write('=');
      buffer.write(promotionType == PieceType.knight
          ? 'N'
          : promotionType!.name[0].toUpperCase());
    }
    return buffer.toString();
  }

  @override
  String toString() => notation;
}
