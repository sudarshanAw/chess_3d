/// Represents a position on the chess board.
/// Row 0 = rank 8 (black's back rank), row 7 = rank 1 (white's back rank).
/// Col 0 = file a, col 7 = file h.
class BoardPosition {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col);

  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  String get algebraic {
    if (!isValid) return '??';
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }

  /// Create from algebraic notation like "e4"
  factory BoardPosition.fromAlgebraic(String notation) {
    final col = notation.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(notation[1]);
    return BoardPosition(row, col);
  }

  BoardPosition offset(int dRow, int dCol) {
    return BoardPosition(row + dRow, col + dCol);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPosition && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => algebraic;
}
