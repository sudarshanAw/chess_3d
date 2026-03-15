import '../models/chess_piece.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';

/// Generates raw moves for each piece type without considering check constraints.
/// Check filtering is done by CheckDetector.
class MoveValidator {
  /// Get all pseudo-legal moves for a piece at the given position.
  /// These moves obey piece movement rules but may leave the king in check.
  static List<BoardPosition> getPseudoLegalMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    BoardPosition? enPassantTarget,
  ) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    switch (piece.type) {
      case PieceType.pawn:
        return _pawnMoves(board, pos, piece, enPassantTarget);
      case PieceType.knight:
        return _knightMoves(board, pos, piece);
      case PieceType.bishop:
        return _bishopMoves(board, pos, piece);
      case PieceType.rook:
        return _rookMoves(board, pos, piece);
      case PieceType.queen:
        return _queenMoves(board, pos, piece);
      case PieceType.king:
        return _kingMoves(board, pos, piece);
    }
  }

  /// Get castling moves for the king (checked separately since they have complex conditions).
  static List<BoardPosition> getCastlingMoves(
    List<List<ChessPiece?>> board,
    BoardPosition kingPos,
    ChessPiece king,
    bool Function(List<List<ChessPiece?>>, PieceColor) isInCheck,
    bool Function(List<List<ChessPiece?>>, BoardPosition, PieceColor) isSquareAttacked,
  ) {
    if (king.hasMoved) return [];
    if (isInCheck(board, king.color)) return [];

    final moves = <BoardPosition>[];
    final row = kingPos.row;

    // Kingside castling (king moves to col 6, rook from col 7 to col 5)
    final kRook = board[row][7];
    if (kRook != null &&
        kRook.type == PieceType.rook &&
        kRook.color == king.color &&
        !kRook.hasMoved) {
      if (board[row][5] == null && board[row][6] == null) {
        // King passes through col 5 and lands on col 6 — neither can be attacked
        if (!isSquareAttacked(board, BoardPosition(row, 5), king.color) &&
            !isSquareAttacked(board, BoardPosition(row, 6), king.color)) {
          moves.add(BoardPosition(row, 6));
        }
      }
    }

    // Queenside castling (king moves to col 2, rook from col 0 to col 3)
    final qRook = board[row][0];
    if (qRook != null &&
        qRook.type == PieceType.rook &&
        qRook.color == king.color &&
        !qRook.hasMoved) {
      if (board[row][1] == null && board[row][2] == null && board[row][3] == null) {
        if (!isSquareAttacked(board, BoardPosition(row, 2), king.color) &&
            !isSquareAttacked(board, BoardPosition(row, 3), king.color)) {
          moves.add(BoardPosition(row, 2));
        }
      }
    }

    return moves;
  }

  static List<BoardPosition> _pawnMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    ChessPiece pawn,
    BoardPosition? enPassantTarget,
  ) {
    final moves = <BoardPosition>[];
    final direction = pawn.color == PieceColor.white ? -1 : 1;
    final startRow = pawn.color == PieceColor.white ? 6 : 1;

    // Forward one square
    final oneStep = pos.offset(direction, 0);
    if (oneStep.isValid && board[oneStep.row][oneStep.col] == null) {
      moves.add(oneStep);

      // Forward two squares from starting position
      if (pos.row == startRow) {
        final twoStep = pos.offset(direction * 2, 0);
        if (twoStep.isValid && board[twoStep.row][twoStep.col] == null) {
          moves.add(twoStep);
        }
      }
    }

    // Diagonal captures
    for (final dc in [-1, 1]) {
      final cap = pos.offset(direction, dc);
      if (!cap.isValid) continue;
      final target = board[cap.row][cap.col];
      if (target != null && target.color != pawn.color) {
        moves.add(cap);
      }
      // En passant
      if (enPassantTarget != null && cap == enPassantTarget) {
        moves.add(cap);
      }
    }

    return moves;
  }

  static List<BoardPosition> _knightMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    ChessPiece knight,
  ) {
    final moves = <BoardPosition>[];
    const offsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1],
    ];
    for (final o in offsets) {
      final target = pos.offset(o[0], o[1]);
      if (!target.isValid) continue;
      final piece = board[target.row][target.col];
      if (piece == null || piece.color != knight.color) {
        moves.add(target);
      }
    }
    return moves;
  }

  static List<BoardPosition> _slidingMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    ChessPiece piece,
    List<List<int>> directions,
  ) {
    final moves = <BoardPosition>[];
    for (final dir in directions) {
      var current = pos;
      while (true) {
        current = current.offset(dir[0], dir[1]);
        if (!current.isValid) break;
        final target = board[current.row][current.col];
        if (target == null) {
          moves.add(current);
        } else {
          if (target.color != piece.color) {
            moves.add(current);
          }
          break;
        }
      }
    }
    return moves;
  }

  static List<BoardPosition> _bishopMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    ChessPiece bishop,
  ) {
    return _slidingMoves(board, pos, bishop, [
      [-1, -1], [-1, 1], [1, -1], [1, 1],
    ]);
  }

  static List<BoardPosition> _rookMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    ChessPiece rook,
  ) {
    return _slidingMoves(board, pos, rook, [
      [-1, 0], [1, 0], [0, -1], [0, 1],
    ]);
  }

  static List<BoardPosition> _queenMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    ChessPiece queen,
  ) {
    return _slidingMoves(board, pos, queen, [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1], [0, 1],
      [1, -1], [1, 0], [1, 1],
    ]);
  }

  static List<BoardPosition> _kingMoves(
    List<List<ChessPiece?>> board,
    BoardPosition pos,
    ChessPiece king,
  ) {
    final moves = <BoardPosition>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final target = pos.offset(dr, dc);
        if (!target.isValid) continue;
        final piece = board[target.row][target.col];
        if (piece == null || piece.color != king.color) {
          moves.add(target);
        }
      }
    }
    return moves;
  }
}
