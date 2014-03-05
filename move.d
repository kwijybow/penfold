import std.stdio, std.string, std.array, std.conv, std.math;
import core.bitop;
import hash;
import chess;
import position;
import tree;
import attacks;
import masks;

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
    tree.enpassant[ply] = squarenum[tree.p.enpassant_target];

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

/*
 ************************************************************
 *                                                          *
 *   We produce rook moves by locating the most advanced    *
 *   rook and then using that square in a magic multiply    *
 *   move generation to quickly identify all the squares    *
 *   rook can reach.  We repeat for each rook.              *
 *                                                          *
 ************************************************************
 */
 
    for (piecebd = tree.p.rooks[side]; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksRook(from, (tree.p.occupied[Color.white] | tree.p.occupied[Color.white])) & tree.p.occupied[enemy];
        temp = from + (Piece.rook << 12);
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
 *   We produce queen moves by locating the most advanced   *
 *   queen and then using that square in a magic multiply   *
 *   move generation to quickly identify all the squares a  *
 *   queen can reach.  We repeat for each queen.            *
 *                                                          *
 ************************************************************
 */
    for (piecebd = tree.p.queens[side]; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksQueen(from, (tree.p.occupied[Color.white] | tree.p.occupied[Color.white])) & tree.p.occupied[enemy];
        temp = from + (Piece.queen << 12);
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
 *   We produce king moves by locating the only king and    *
 *   then using that <from> square as an index into the     *
 *   precomputed king_attacks data.                         *
 *                                                          *
 ************************************************************
 */    
 
    from = tree.p.kingsq[side];
    moves = king_attacks[from] & tree.p.occupied[enemy];
    temp = from + (Piece.king << 12);
    to = Advanced(side, moves);
    for ( ; moves ; Clear(to, moves)) {
        to = Advanced(side, moves);       
        tree.move_list[ply][move_index] = temp | (to << 6) | (abs(tree.p.board[to]) << 15);
        move_index++;
        num_moves++;
    }

/*
 ************************************************************
 *                                                          *
 *   Now, produce pawn moves.  This is done differently due *
 *   to inconsistencies in the way a pawn moves when it     *
 *   captures as opposed to normal non-capturing moves.     *
 *   Another exception is capturing enpassant.  The first   *
 *   step is to generate all possible pawn promotions.  We  *
 *   do this by removing all pawns but those on the 7th     *
 *   rank and then advancing them if the square in front is *
 *   empty.                                                 *
 *                                                          *
 ************************************************************
 */
 
    if (side == Color.white) {
        promotions = ((tree.p.pawns[Color.white] & rankmask_by_name["7"]) << 8) & ~(tree.p.occupied[Color.white] | tree.p.occupied[Color.black]);
    }
    else {
        promotions = ((tree.p.pawns[Color.black] & rankmask_by_name["2"]) >> 8) & ~(tree.p.occupied[Color.white] | tree.p.occupied[Color.black]);
    }
    to = Advanced(side, promotions);
    for (; promotions; Clear(to, promotions)) {
      to = Advanced(side, promotions);
      tree.move_list[ply][move_index] =
          (to + pawnadv1[side]) | (to << 6) | (Piece.pawn << 12) | (Piece.queen << 18);
    }

    target = tree.p.occupied[enemy] | SetMask(tree.enpassant[ply]);
    if (side == Color.white) {
        pcapturesl = ((tree.p.pawns[Color.white] & ~(filemask_by_name["a"])) << 7) & target;
        pcapturesr = ((tree.p.pawns[Color.white] & ~(filemask_by_name["h"])) << 9) & target;
    }
    else {
        pcapturesl = ((tree.p.pawns[Color.black] & ~(filemask_by_name["a"])) >> 9) & target;
        pcapturesr = ((tree.p.pawns[Color.black] & ~(filemask_by_name["h"])) >> 7) & target;
    }
    to = Advanced(side, pcapturesl);
    for (; pcapturesl; Clear(to, pcapturesl)) {
        to = Advanced(side, pcapturesl);
        common = (to + capleft[side]) | (to << 6) | (Piece.pawn << 12);
        if (side == Color.white)
            if (to < 56) {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15);
                move_index++;
                num_moves++;
            }    
            else {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15) | (Piece.queen << 18);
                move_index++;
                num_moves++;
            }
        else
            if (to > 7) {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15);
                move_index++;
                num_moves++;
            }    
            else {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15) | (Piece.queen << 18);
                move_index++;
                num_moves++;
            }
    }
    to = Advanced(side, pcapturesr);
    for (; pcapturesl; Clear(to, pcapturesr)) {
        to = Advanced(side, pcapturesr);
        common = (to + capright[side]) | (to << 6) | (Piece.pawn << 12);
        if (side == Color.white)
            if (to < 56) {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15);
                move_index++;
                num_moves++;
            }    
            else {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15) | (Piece.queen << 18);
                move_index++;
                num_moves++;
            }
        else
            if (to > 7) {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15);
                move_index++;
                num_moves++;
            }    
            else {
                tree.move_list[ply][move_index] = common | (abs(tree.p.board[to]) << 15) | (Piece.queen << 18);
                move_index++;
                num_moves++;
            }
    }    
    return (num_moves);
}
