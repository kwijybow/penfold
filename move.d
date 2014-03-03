import std.stdio, std.string, std.array, std.conv;
import core.bitop;
import hash;
import chess;
import position;
import tree;

/*
 *******************************************************************************
 *                                                                             *
 *   GenerateCaptures() is used to generate capture and pawn promotion moves   *
 *   from the current position.                                                *
 *                                                                             *
 *   The destination square set is the set of squares occupied by opponent     *
 *   pieces, plus the set of squares on the 8th rank that pawns can advance to *
 *   and promote.                                                              *
 *                                                                             *
 *******************************************************************************
 */
 
ref int GenerateCaptures(ref Tree tree, int ply, int side, ref int move) {
  ulong target, piecebd, moves;
  ulong promotions, pcapturesl, pcapturesr;
  int from, to, temp, common, enemy = Flip(side);

/*
 ************************************************************
 *                                                          *
 *   We produce knight moves by locating the most advanced  *
 *   knight and then using that <from> square as an index   *
 *   into the precomputed knight_attacks data.  We repeat   *
 *   for each knight.                                       *
 *                                                          *
 ************************************************************
 */
 
  for (piecebd = tree.p.knights[side]; piecebd; Clear(from, piecebd)) {
    from = Advanced(side, piecebd);
    moves = knight_attacks[from] & tree.p.occupied[enemy];
    temp = from + (Piece.knight << 12);
//    Unpack(side, move, moves, temp);
  }

 return (move);
}
