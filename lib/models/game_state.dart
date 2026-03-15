import 'chess_piece.dart';
import 'board_position.dart';
import 'move.dart';

enum GameStatus { playing, check, checkmate, stalemate, drawInsufficient, drawFiftyMove, drawRepetition }

class GameState {
  final List<List<ChessPiece?>> board;
  final PieceColor currentTurn;
  final List<ChessMove> moveHistory;
  final List<ChessPiece> capturedWhite; // white pieces captured by black
  final List<ChessPiece> capturedBlack; // black pieces captured by white
  final GameStatus status;
  final BoardPosition? selectedPosition;
  final List<BoardPosition> validMoves;
  final BoardPosition? enPassantTarget; // the square where en passant capture can happen
  final int halfMoveClock; // for fifty-move rule
  final int fullMoveNumber;
  final List<String> positionHistory; // for threefold repetition
  final BoardPosition? kingInCheck;
  final bool isAnimating;

  const GameState({
    required this.board,
    this.currentTurn = PieceColor.white,
    this.moveHistory = const [],
    this.capturedWhite = const [],
    this.capturedBlack = const [],
    this.status = GameStatus.playing,
    this.selectedPosition,
    this.validMoves = const [],
    this.enPassantTarget,
    this.halfMoveClock = 0,
    this.fullMoveNumber = 1,
    this.positionHistory = const [],
    this.kingInCheck,
    this.isAnimating = false,
  });

  GameState copyWith({
    List<List<ChessPiece?>>? board,
    PieceColor? currentTurn,
    List<ChessMove>? moveHistory,
    List<ChessPiece>? capturedWhite,
    List<ChessPiece>? capturedBlack,
    GameStatus? status,
    BoardPosition? selectedPosition,
    List<BoardPosition>? validMoves,
    BoardPosition? enPassantTarget,
    int? halfMoveClock,
    int? fullMoveNumber,
    List<String>? positionHistory,
    BoardPosition? kingInCheck,
    bool? isAnimating,
    bool clearSelected = false,
    bool clearEnPassant = false,
    bool clearKingInCheck = false,
  }) {
    return GameState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      moveHistory: moveHistory ?? this.moveHistory,
      capturedWhite: capturedWhite ?? this.capturedWhite,
      capturedBlack: capturedBlack ?? this.capturedBlack,
      status: status ?? this.status,
      selectedPosition: clearSelected ? null : (selectedPosition ?? this.selectedPosition),
      validMoves: clearSelected ? [] : (validMoves ?? this.validMoves),
      enPassantTarget: clearEnPassant ? null : (enPassantTarget ?? this.enPassantTarget),
      halfMoveClock: halfMoveClock ?? this.halfMoveClock,
      fullMoveNumber: fullMoveNumber ?? this.fullMoveNumber,
      positionHistory: positionHistory ?? this.positionHistory,
      kingInCheck: clearKingInCheck ? null : (kingInCheck ?? this.kingInCheck),
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  /// Deep copy the board array
  static List<List<ChessPiece?>> cloneBoard(List<List<ChessPiece?>> board) {
    return board.map((row) => row.map((piece) => piece).toList()).toList();
  }

  /// Create the standard starting position
  factory GameState.initial() {
    final board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));

    // Black pieces (row 0 = rank 8)
    board[0][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
    board[0][1] = const ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[0][2] = const ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[0][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.black);
    board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    board[0][5] = const ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[0][6] = const ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[0][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
    for (int c = 0; c < 8; c++) {
      board[1][c] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    }

    // White pieces (row 7 = rank 1)
    board[7][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[7][1] = const ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][2] = const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[7][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[7][5] = const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[7][6] = const ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    for (int c = 0; c < 8; c++) {
      board[6][c] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    }

    final initial = GameState(board: board);
    return initial.copyWith(
      positionHistory: [computePositionKey(board, PieceColor.white, null)],
    );
  }

  /// Compute a string key representing the current position for repetition detection
  static String computePositionKey(
      List<List<ChessPiece?>> board, PieceColor turn, BoardPosition? epTarget) {
    final buf = StringBuffer();
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p == null) {
          buf.write('.');
        } else {
          String ch;
          switch (p.type) {
            case PieceType.king:
              ch = 'k';
            case PieceType.queen:
              ch = 'q';
            case PieceType.rook:
              ch = 'r';
            case PieceType.bishop:
              ch = 'b';
            case PieceType.knight:
              ch = 'n';
            case PieceType.pawn:
              ch = 'p';
          }
          buf.write(p.color == PieceColor.white ? ch.toUpperCase() : ch);
        }
      }
    }
    buf.write(turn == PieceColor.white ? 'w' : 'b');
    if (epTarget != null) {
      buf.write(epTarget.algebraic);
    }
    return buf.toString();
  }

  String get positionKey =>
      computePositionKey(board, currentTurn, enPassantTarget);

  bool get isGameOver =>
      status == GameStatus.checkmate ||
      status == GameStatus.stalemate ||
      status == GameStatus.drawInsufficient ||
      status == GameStatus.drawFiftyMove ||
      status == GameStatus.drawRepetition;

  String get statusText {
    switch (status) {
      case GameStatus.playing:
        return '${currentTurn == PieceColor.white ? "White" : "Black"} to move';
      case GameStatus.check:
        return '${currentTurn == PieceColor.white ? "White" : "Black"} is in Check!';
      case GameStatus.checkmate:
        final winner = currentTurn == PieceColor.white ? 'Black' : 'White';
        return 'Checkmate! $winner wins!';
      case GameStatus.stalemate:
        return 'Stalemate! Draw.';
      case GameStatus.drawInsufficient:
        return 'Draw - Insufficient material';
      case GameStatus.drawFiftyMove:
        return 'Draw - Fifty-move rule';
      case GameStatus.drawRepetition:
        return 'Draw - Threefold repetition';
    }
  }
}
