import '../models/chess_piece.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';
import 'move_validator.dart';

/// Handles check detection, legal move filtering, and square attack detection.
class CheckDetector {
  /// Find the king of the given color on the board.
  static BoardPosition? findKing(List<List<ChessPiece?>> board, PieceColor color) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p != null && p.type == PieceType.king && p.color == color) {
          return BoardPosition(r, c);
        }
      }
    }
    return null;
  }

  /// Check if the given color's king is in check.
  static bool isInCheck(List<List<ChessPiece?>> board, PieceColor color) {
    final kingPos = findKing(board, color);
    if (kingPos == null) return false;
    return isSquareAttacked(board, kingPos, color);
  }

  /// Check if a square is attacked by any piece of the opponent of `defendingColor`.
  static bool isSquareAttacked(
    List<List<ChessPiece?>> board,
    BoardPosition square,
    PieceColor defendingColor,
  ) {
    final attackerColor =
        defendingColor == PieceColor.white ? PieceColor.black : PieceColor.white;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece == null || piece.color != attackerColor) continue;

        final pos = BoardPosition(r, c);
        // Use pseudo-legal moves (no en passant needed for attack detection on non-pawn squares,
        // but we pass null since en passant doesn't affect attack squares for check detection)
        final moves = MoveValidator.getPseudoLegalMoves(board, pos, null);
        // For pawns, only diagonal moves are attacks. The pseudo-legal moves include
        // forward non-capture moves which are NOT attacks. We need to filter.
        if (piece.type == PieceType.pawn) {
          final direction = piece.color == PieceColor.white ? -1 : 1;
          // Pawn attacks diagonally
          for (final dc in [-1, 1]) {
            final attackSquare = pos.offset(direction, dc);
            if (attackSquare == square) return true;
          }
        } else {
          if (moves.contains(square)) return true;
        }
      }
    }
    return false;
  }

  /// Filter pseudo-legal moves to only those that don't leave the king in check.
  static List<BoardPosition> filterLegalMoves(
    List<List<ChessPiece?>> board,
    BoardPosition from,
    List<BoardPosition> pseudoMoves,
    PieceColor color,
    BoardPosition? enPassantTarget,
  ) {
    final legal = <BoardPosition>[];
    for (final to in pseudoMoves) {
      if (_isMoveLegal(board, from, to, color, enPassantTarget)) {
        legal.add(to);
      }
    }
    return legal;
  }

  /// Simulate a move and check if the king is still safe.
  static bool _isMoveLegal(
    List<List<ChessPiece?>> board,
    BoardPosition from,
    BoardPosition to,
    PieceColor color,
    BoardPosition? enPassantTarget,
  ) {
    // Make a temporary copy
    final tempBoard = GameState.cloneBoard(board);
    final piece = tempBoard[from.row][from.col]!;

    // Handle en passant capture
    if (piece.type == PieceType.pawn && enPassantTarget != null && to == enPassantTarget) {
      final capturedRow = from.row; // the captured pawn is on the same row as the moving pawn
      tempBoard[capturedRow][to.col] = null;
    }

    // Execute the move
    tempBoard[to.row][to.col] = piece;
    tempBoard[from.row][from.col] = null;

    // Check if our king is in check after the move
    return !isInCheck(tempBoard, color);
  }

  /// Check if a player has any legal moves at all.
  static bool hasAnyLegalMoves(
    List<List<ChessPiece?>> board,
    PieceColor color,
    BoardPosition? enPassantTarget,
  ) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece == null || piece.color != color) continue;

        final pos = BoardPosition(r, c);
        final pseudoMoves =
            MoveValidator.getPseudoLegalMoves(board, pos, enPassantTarget);

        // Add castling moves for king
        if (piece.type == PieceType.king) {
          pseudoMoves.addAll(MoveValidator.getCastlingMoves(
            board,
            pos,
            piece,
            isInCheck,
            isSquareAttacked,
          ));
        }

        final legalMoves =
            filterLegalMoves(board, pos, pseudoMoves, color, enPassantTarget);
        if (legalMoves.isNotEmpty) return true;
      }
    }
    return false;
  }

  /// Get all legal moves for a piece at the given position.
  static List<BoardPosition> getLegalMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    BoardPosition? enPassantTarget,
  ) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    final pseudoMoves =
        MoveValidator.getPseudoLegalMoves(board, pos, enPassantTarget);

    if (piece.type == PieceType.king) {
      pseudoMoves.addAll(MoveValidator.getCastlingMoves(
        board,
        pos,
        piece,
        isInCheck,
        isSquareAttacked,
      ));
    }

    return filterLegalMoves(board, pos, pseudoMoves, piece.color, enPassantTarget);
  }
}
