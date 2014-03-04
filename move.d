import std.stdio, std.string, std.array, std.conv, std.math;
import core.bitop;
import hash;
import chess;
import position;
import tree;
import attacks;

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
 
int GenerateCaptures(ref Tree tree, int ply, int side, ref int move_index) {
    ulong target, piecebd, moves;
    ulong promotions, pcapturesl, pcapturesr;
    int from, to, temp, common, enemy = Flip(side);
    int num_moves = 0;
  
    tree.p.updateBoard();

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
        to = Advanced(side, moves);
        for ( ; moves ; Clear(to, moves)) {
            to = Advanced(side, moves);       
            tree.move_list[ply][move_index] = temp | (to << 6) | (abs(tree.p.board[to]) << 15);
            move_index++;
            num_moves++;
        }
    }
    
/*
 ************************************************************
 *                                                          *
 *   We produce bishop moves by locating the most advanced  *
 *   bishop and then using that square in a magic multiply  *
 *   move generation to quickly identify all the squares a  *
 *   bishop can reach.  We repeat for each bishop.          *
 *                                                          *
 ************************************************************
 */    
    
    for (piecebd = tree.p.bishops[side]; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksBishop(from, (tree.p.occupied[Color.white] | tree.p.occupied[Color.white])) & tree.p.occupied[enemy];
        temp = from + (Piece.bishop << 12);
        to = Advanced(side, moves);
        for ( ; moves ; Clear(to, moves)) {
            to = Advanced(side, moves);       
            tree.move_list[ply][move_index] = temp | (to << 6) | (abs(tree.p.board[to]) << 15);
            move_index++;
            num_moves++;
        }
    }
    
    return (num_moves);
}
