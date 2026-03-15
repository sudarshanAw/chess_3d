enum PieceType { king, queen, rook, bishop, knight, pawn }

enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  final bool hasMoved;

  const ChessPiece({
    required this.type,
    required this.color,
    this.hasMoved = false,
  });

  ChessPiece copyWith({PieceType? type, PieceColor? color, bool? hasMoved}) {
    return ChessPiece(
      type: type ?? this.type,
      color: color ?? this.color,
      hasMoved: hasMoved ?? this.hasMoved,
    );
  }

  String get symbol {
    const symbols = {
      PieceType.king: ['♔', '♚'],
      PieceType.queen: ['♕', '♛'],
      PieceType.rook: ['♖', '♜'],
      PieceType.bishop: ['♗', '♝'],
      PieceType.knight: ['♘', '♞'],
      PieceType.pawn: ['♙', '♟'],
    };
    return symbols[type]![color == PieceColor.white ? 0 : 1];
  }

  String get name {
    return '${color == PieceColor.white ? "White" : "Black"} ${type.name}';
  }

  int get materialValue {
    switch (type) {
      case PieceType.king:
        return 0;
      case PieceType.queen:
        return 9;
      case PieceType.rook:
        return 5;
      case PieceType.bishop:
        return 3;
      case PieceType.knight:
        return 3;
      case PieceType.pawn:
        return 1;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessPiece &&
          type == other.type &&
          color == other.color &&
          hasMoved == other.hasMoved;

  @override
  int get hashCode => Object.hash(type, color, hasMoved);

  @override
  String toString() => '${color.name} ${type.name}${hasMoved ? " (moved)" : ""}';
}
