import 'dart:async';
import '../models/chess_piece.dart';
import '../models/board_position.dart';
import '../models/move.dart';
import '../models/game_state.dart';
import 'check_detector.dart';
import 'game_rules.dart';

/// Central game controller. Manages state, executes moves, and enforces rules.
class BoardManager {
  GameState _state;
  final StreamController<GameState> _stateController =
      StreamController<GameState>.broadcast();

  // Callback for pawn promotion — set by the presentation layer.
  Future<PieceType> Function()? onPromotionRequired;

  BoardManager() : _state = GameState.initial();

  GameState get state => _state;
  Stream<GameState> get stateStream => _stateController.stream;

  void _emit(GameState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Handle a tap on a board square.
  Future<void> onSquareTapped(BoardPosition pos) async {
    if (_state.isGameOver || _state.isAnimating) return;

    final piece = _state.board[pos.row][pos.col];

    // If a piece is already selected
    if (_state.selectedPosition != null) {
      // Tapping the same piece deselects it
      if (pos == _state.selectedPosition) {
        _emit(_state.copyWith(clearSelected: true));
        return;
      }

      // Tapping a valid move square executes the move
      if (_state.validMoves.contains(pos)) {
        await _executeMove(_state.selectedPosition!, pos);
        return;
      }

      // Tapping another piece of the same color selects it
      if (piece != null && piece.color == _state.currentTurn) {
        _selectPiece(pos);
        return;
      }

      // Tapping an invalid square deselects
      _emit(_state.copyWith(clearSelected: true));
      return;
    }

    // No piece selected — select if it's the current player's piece
    if (piece != null && piece.color == _state.currentTurn) {
      _selectPiece(pos);
    }
  }

  void _selectPiece(BoardPosition pos) {
    final legalMoves = CheckDetector.getLegalMoves(
      _state.board,
      pos,
      _state.enPassantTarget,
    );
    _emit(_state.copyWith(
      selectedPosition: pos,
      validMoves: legalMoves,
    ));
  }

  Future<void> _executeMove(BoardPosition from, BoardPosition to) async {
    final board = GameState.cloneBoard(_state.board);
    final piece = board[from.row][from.col]!;
    ChessPiece? captured = board[to.row][to.col];
    MoveType moveType = captured != null ? MoveType.capture : MoveType.normal;
    PieceType? promotionType;
    BoardPosition? newEnPassantTarget;

    // Save state for undo
    final boardBefore = GameState.cloneBoard(_state.board);
    final epBefore = _state.enPassantTarget;
    final hmcBefore = _state.halfMoveClock;

    // Determine move type and handle special moves

    // En passant
    if (piece.type == PieceType.pawn &&
        _state.enPassantTarget != null &&
        to == _state.enPassantTarget) {
      moveType = MoveType.enPassant;
      final capturedRow = from.row;
      captured = board[capturedRow][to.col];
      board[capturedRow][to.col] = null;
    }

    // Castling
    if (piece.type == PieceType.king && (from.col - to.col).abs() == 2) {
      if (to.col == 6) {
        // Kingside
        moveType = MoveType.castleKingside;
        board[from.row][5] = board[from.row][7]?.copyWith(hasMoved: true);
        board[from.row][7] = null;
      } else if (to.col == 2) {
        // Queenside
        moveType = MoveType.castleQueenside;
        board[from.row][3] = board[from.row][0]?.copyWith(hasMoved: true);
        board[from.row][0] = null;
      }
    }

    // Pawn double push — set en passant target
    if (piece.type == PieceType.pawn && (from.row - to.row).abs() == 2) {
      final epRow = (from.row + to.row) ~/ 2;
      newEnPassantTarget = BoardPosition(epRow, from.col);
    }

    // Execute the basic move
    board[to.row][to.col] = piece.copyWith(hasMoved: true);
    board[from.row][from.col] = null;

    // Pawn promotion
    if (piece.type == PieceType.pawn && (to.row == 0 || to.row == 7)) {
      moveType = captured != null ? MoveType.promotion : MoveType.promotion;
      if (captured != null) moveType = MoveType.promotion;

      // Ask for promotion choice
      if (onPromotionRequired != null) {
        // Temporarily update board so the UI can show the position
        _emit(_state.copyWith(
          board: board,
          clearSelected: true,
          isAnimating: true,
        ));
        promotionType = await onPromotionRequired!();
      } else {
        promotionType = PieceType.queen;
      }

      board[to.row][to.col] = ChessPiece(
        type: promotionType,
        color: piece.color,
        hasMoved: true,
      );
    }

    // Build the move record
    final move = ChessMove(
      from: from,
      to: to,
      piece: piece,
      capturedPiece: captured,
      moveType: moveType,
      promotionType: promotionType,
      boardBefore: boardBefore,
      enPassantTargetBefore: epBefore,
      halfMoveClockBefore: hmcBefore,
    );

    // Update captured pieces
    final capturedWhite = List<ChessPiece>.from(_state.capturedWhite);
    final capturedBlack = List<ChessPiece>.from(_state.capturedBlack);
    if (captured != null) {
      if (captured.color == PieceColor.white) {
        capturedWhite.add(captured);
      } else {
        capturedBlack.add(captured);
      }
    }

    // Update half-move clock (reset on pawn move or capture)
    int halfMoveClock = _state.halfMoveClock + 1;
    if (piece.type == PieceType.pawn || captured != null) {
      halfMoveClock = 0;
    }

    // Update full move number
    int fullMoveNumber = _state.fullMoveNumber;
    if (piece.color == PieceColor.black) {
      fullMoveNumber++;
    }

    final nextTurn = piece.color == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    // Compute position key for repetition detection
    final posKey = GameState.computePositionKey(board, nextTurn, newEnPassantTarget);
    final positionHistory = [..._state.positionHistory, posKey];

    // Check game status
    final inCheck = CheckDetector.isInCheck(board, nextTurn);
    final hasLegal = CheckDetector.hasAnyLegalMoves(board, nextTurn, newEnPassantTarget);

    final status = GameRules.determineStatus(
      board,
      nextTurn,
      hasLegal,
      inCheck,
      halfMoveClock,
      positionHistory,
    );

    BoardPosition? kingInCheck;
    if (inCheck) {
      kingInCheck = CheckDetector.findKing(board, nextTurn);
    }

    _emit(GameState(
      board: board,
      currentTurn: nextTurn,
      moveHistory: [..._state.moveHistory, move],
      capturedWhite: capturedWhite,
      capturedBlack: capturedBlack,
      status: status,
      enPassantTarget: newEnPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      positionHistory: positionHistory,
      kingInCheck: kingInCheck,
      isAnimating: false,
    ));
  }

  /// Undo the last move.
  void undoLastMove() {
    if (_state.moveHistory.isEmpty || _state.isAnimating) return;

    final lastMove = _state.moveHistory.last;
    final boardBefore = lastMove.boardBefore;
    if (boardBefore == null) return;

    final newHistory = List<ChessMove>.from(_state.moveHistory)..removeLast();

    // Restore captured pieces
    final capturedWhite = List<ChessPiece>.from(_state.capturedWhite);
    final capturedBlack = List<ChessPiece>.from(_state.capturedBlack);
    if (lastMove.capturedPiece != null) {
      if (lastMove.capturedPiece!.color == PieceColor.white) {
        capturedWhite.removeLast();
      } else {
        capturedBlack.removeLast();
      }
    }

    // Restore position history
    final posHistory = List<String>.from(_state.positionHistory);
    if (posHistory.isNotEmpty) posHistory.removeLast();

    final prevTurn = lastMove.piece.color;

    // Restore full move number
    int fullMoveNumber = _state.fullMoveNumber;
    if (prevTurn == PieceColor.black) {
      fullMoveNumber--;
    }

    // Check status for the restored position
    final inCheck = CheckDetector.isInCheck(boardBefore, prevTurn);
    final hasLegal = CheckDetector.hasAnyLegalMoves(
        boardBefore, prevTurn, lastMove.enPassantTargetBefore);

    final status = GameRules.determineStatus(
      boardBefore,
      prevTurn,
      hasLegal,
      inCheck,
      lastMove.halfMoveClockBefore,
      posHistory,
    );

    BoardPosition? kingInCheck;
    if (inCheck) {
      kingInCheck = CheckDetector.findKing(boardBefore, prevTurn);
    }

    _emit(GameState(
      board: boardBefore,
      currentTurn: prevTurn,
      moveHistory: newHistory,
      capturedWhite: capturedWhite,
      capturedBlack: capturedBlack,
      status: status,
      enPassantTarget: lastMove.enPassantTargetBefore,
      halfMoveClock: lastMove.halfMoveClockBefore,
      fullMoveNumber: fullMoveNumber,
      positionHistory: posHistory,
      kingInCheck: kingInCheck,
    ));
  }

  /// Restart the game.
  void restart() {
    _emit(GameState.initial());
  }

  void dispose() {
    _stateController.close();
  }
}
