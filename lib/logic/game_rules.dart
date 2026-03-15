import '../models/chess_piece.dart';
import '../models/game_state.dart';

/// Handles draw detection: insufficient material, fifty-move rule, threefold repetition.
class GameRules {
  /// Check for insufficient material draw.
  /// Insufficient material: K vs K, K+B vs K, K+N vs K, K+B vs K+B (same color bishops).
  static bool isInsufficientMaterial(List<List<ChessPiece?>> board) {
    final whitePieces = <ChessPiece>[];
    final blackPieces = <ChessPiece>[];

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p == null) continue;
        if (p.color == PieceColor.white) {
          whitePieces.add(p);
        } else {
          blackPieces.add(p);
        }
      }
    }

    // K vs K
    if (whitePieces.length == 1 && blackPieces.length == 1) return true;

    // K+B vs K or K+N vs K
    if (whitePieces.length == 1 && blackPieces.length == 2) {
      final extra = blackPieces.firstWhere((p) => p.type != PieceType.king);
      if (extra.type == PieceType.bishop || extra.type == PieceType.knight) {
        return true;
      }
    }
    if (blackPieces.length == 1 && whitePieces.length == 2) {
      final extra = whitePieces.firstWhere((p) => p.type != PieceType.king);
      if (extra.type == PieceType.bishop || extra.type == PieceType.knight) {
        return true;
      }
    }

    // K+B vs K+B with bishops on same color squares
    if (whitePieces.length == 2 && blackPieces.length == 2) {
      final wBishop = whitePieces.where((p) => p.type == PieceType.bishop).toList();
      final bBishop = blackPieces.where((p) => p.type == PieceType.bishop).toList();
      if (wBishop.length == 1 && bBishop.length == 1) {
        // Find their positions to check square color
        int? wBishopSquareColor;
        int? bBishopSquareColor;
        for (int r = 0; r < 8; r++) {
          for (int c = 0; c < 8; c++) {
            final p = board[r][c];
            if (p == null) continue;
            if (p.type == PieceType.bishop && p.color == PieceColor.white) {
              wBishopSquareColor = (r + c) % 2;
            }
            if (p.type == PieceType.bishop && p.color == PieceColor.black) {
              bBishopSquareColor = (r + c) % 2;
            }
          }
        }
        if (wBishopSquareColor != null &&
            bBishopSquareColor != null &&
            wBishopSquareColor == bBishopSquareColor) {
          return true;
        }
      }
    }

    return false;
  }

  /// Check for fifty-move rule (100 half-moves without pawn move or capture).
  static bool isFiftyMoveRule(int halfMoveClock) {
    return halfMoveClock >= 100;
  }

  /// Check for threefold repetition.
  static bool isThreefoldRepetition(List<String> positionHistory) {
    if (positionHistory.isEmpty) return false;
    final currentPos = positionHistory.last;
    int count = 0;
    for (final pos in positionHistory) {
      if (pos == currentPos) count++;
      if (count >= 3) return true;
    }
    return false;
  }

  /// Determine the game status after a move.
  static GameStatus determineStatus(
    List<List<ChessPiece?>> board,
    PieceColor currentTurn,
    bool hasLegalMoves,
    bool isInCheck,
    int halfMoveClock,
    List<String> positionHistory,
  ) {
    if (!hasLegalMoves) {
      if (isInCheck) return GameStatus.checkmate;
      return GameStatus.stalemate;
    }

    if (isInsufficientMaterial(board)) return GameStatus.drawInsufficient;
    if (isFiftyMoveRule(halfMoveClock)) return GameStatus.drawFiftyMove;
    if (isThreefoldRepetition(positionHistory)) return GameStatus.drawRepetition;
    if (isInCheck) return GameStatus.check;

    return GameStatus.playing;
  }
}
