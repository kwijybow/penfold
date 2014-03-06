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
        //to = Advanced(side, moves);
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
        //to = Advanced(side, moves);
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
        //to = Advanced(side, moves);
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
        //to = Advanced(side, moves);
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
    //to = Advanced(side, moves);
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
    //to = Advanced(side, promotions);
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
    //to = Advanced(side, pcapturesl);
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
    //to = Advanced(side, pcapturesr);
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


/* modified 11/30/10 */
/*
 *******************************************************************************
 *                                                                             *
 *   GenerateChecks() is used to generate non-capture moves from the current   *
 *   position.                                                                 *
 *                                                                             *
 *   The first pass produces a bitmap that contains the squares a particular   *
 *   piece type would attack if sitting on the square the enemy king sits on.  *
 *   We then use each of these squares as a source and check to see if the     *
 *   same piece type attacks one of these common targets.  If so, we can move  *
 *   that piece to that square and it will directly attack the king.  We do    *
 *   this for pawns, knights, bishops, rooks and queens to produce the set of  *
 *   "direct checking moves."                                                  *
 *                                                                             *
 *   Then we generate discovered checks in two passes, once for diagonal       *
 *   attacks and once for rank/file attacks (we do it in two passes since a    *
 *   rook can't produce a discovered check along a rank or file since it moves *
 *   in that direction as well.  For diagonals, we first generate the bishop   *
 *   attacks from the enemy king square and mask them with the friendly piece  *
 *   occupied squares bitmap.  This gives us a set of up to 4 "blocking        *
 *   pieces" that could be preventing a check.  We then remove them via the    *
 *   "magic move generation" tricks, and see if we now reach friendly bishops  *
 *   or queens on those diagonals.  If we have a friendly blocker, and a       *
 *   friendly diagonal mover behind that blocker, then moving the blocker is   *
 *   a discovered check (and there could be double-checks included but we do   *
 *   not check for that since a single check is good enough).  We repeat this  *
 *   for the ranks/files and we are done.                                      *
 *                                                                             *
 *   For the present, this code does not produce discovered checks by the      *
 *   king since all king moves are not discovered checks because the king can  *
 *   move in the same direction as the piece it blocks and not uncover the     *
 *   attack.  This might be fixed at some point, but it is rare enough to not  *
 *   be an issue except in far endgames.                                       *
 *                                                                             *
 *******************************************************************************
 */

int GenerateChecks(ref Tree tree, int ply, int side, ref int move_index) {
  ulong temp_target, target, piecebd, moves;
  ulong padvances1, blockers, checkers;
  int from, to, promote, temp, enemy = Flip(side);
  int num_moves = 0;

/*
 *********************************************************************
 *                                                                   *
 *  First pass:  produce direct checks.  For each piece type, we     *
 *  pretend that a piece of that type stands on the square of the    *
 *  king and we generate attacks from that square for that piece.    *
 *  Now, if we can find any piece of that type that attacks one of   *
 *  those squares, then that piece move would deliver a direct       *
 *  check to the enemy king.  Easy, wasn't it?                       *
 *                                                                   *
 *********************************************************************
 */
    target = ~(tree.p.occupied[Color.white] | tree.p.occupied[Color.black]);
/*
 ************************************************************
 *                                                          *
 *  Knight direct checks.                                   *
 *                                                          *
 ************************************************************
 */
 
    temp_target = target & knight_attacks[tree.p.kingsq[enemy]];
    for (piecebd = tree.p.knights[side]; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = knight_attacks[from] & temp_target;
        temp = from + (Piece.knight << 12);
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
 *  Bishop direct checks.                                   *
 *                                                          *
 ************************************************************
 */
 
    temp_target = target & AttacksBishop(tree.p.kingsq[enemy], (tree.p.occupied[Color.white] | tree.p.occupied[Color.black]));
    for (piecebd = tree.p.bishops[side]; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksBishop(from, (tree.p.occupied[Color.white] | tree.p.occupied[Color.black])) & temp_target;
        temp = from + (Piece.bishop << 12);
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
 *  Rook direct checks.                                     *
 *                                                          *
 ************************************************************
 */
 
    temp_target = target & AttacksRook(tree.p.kingsq[enemy], (tree.p.occupied[Color.white] | tree.p.occupied[Color.black]));
    for (piecebd = tree.p.rooks[side]; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksRook(from, (tree.p.occupied[Color.white] | tree.p.occupied[Color.black])) & temp_target;
        temp = from + (Piece.rook << 12);
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
 *  Queen direct checks.                                    *
 *                                                          *
 ************************************************************
 */

    temp_target = target & AttacksQueen(tree.p.kingsq[enemy], (tree.p.occupied[Color.white] | tree.p.occupied[Color.black]));
    for (piecebd = tree.p.rooks[side]; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksQueen(from, (tree.p.occupied[Color.white] | tree.p.occupied[Color.black])) & temp_target;
        temp = from + (Piece.queen << 12);
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
 *   Pawn direct checks.                                    *
 *                                                          *
 ************************************************************
 */
 
  temp_target = target & pawn_attacks[enemy][tree.p.kingsq[enemy]];
  if (side == Color.white) 
      padvances1 = (tree.p.pawns[Color.white] << 8) & temp_target;
  else
      padvances1 = (tree.p.pawns[Color.black] >> 8) & temp_target;
  for (; padvances1; Clear(to, padvances1)) {
    to = Advanced(side, padvances1);
    tree.move_list[ply][move_index] = (to + pawnadv1[side]) | (to << 6) | (Piece.pawn << 12);
  }
  
/*
 *********************************************************************
 *                                                                   *
 *  Second pass:  produce discovered checks.  Here we do things a    *
 *  bit differently.  We first take diagonal movers.  From the enemy *
 *  king's position, we generate diagonal moves to see if any of     *
 *  them end at one of our pieces that does not slide diagonally,    *
 *  such as a rook, knight or pawn.  If we find one, we look on down *
 *  that diagonal to see if we now find a diagonal mover (queen or   *
 *  bishop).  If so, any legal move by this piece (except captures   *
 *  which have already been generated) will be a discovered check    *
 *  that needs to be searched.  We do the same for vertical /        *
 *  horizontal rays that are blocked by pawns, bishops, knights or   *
 *  kings that would hide a discovered check by a rook or queen.     *
 *                                                                   *
 *********************************************************************
 */
/*
 ************************************************************
 *                                                          *
 *   First we look for diagonal discovered attacks.  Once   *
 *   we know which squares hold pieces that create a        *
 *   discovered check when they move, we generate them      *
 *   piece type by piece type.                              *
 *                                                          *
 ************************************************************
 */
/* 
  blockers =
      AttacksBishop(KingSQ(enemy),
      OccupiedSquares) & (Rooks(side) | Knights(side) | Pawns(side));
  if (blockers) {
    checkers =
        AttacksBishop(KingSQ(enemy),
        OccupiedSquares & ~blockers) & (Bishops(side) | Queens(side));
    if (checkers) {
      if ((plus7dir[KingSQ(enemy)] & blockers)
          && !(plus7dir[KingSQ(enemy)] & checkers))
        blockers &= ~plus7dir[KingSQ(enemy)];
      if ((plus9dir[KingSQ(enemy)] & blockers)
          && !(plus9dir[KingSQ(enemy)] & checkers))
        blockers &= ~plus9dir[KingSQ(enemy)];
      if ((minus7dir[KingSQ(enemy)] & blockers)
          && !(minus7dir[KingSQ(enemy)] & checkers))
        blockers &= ~minus7dir[KingSQ(enemy)];
      if ((minus9dir[KingSQ(enemy)] & blockers)
          && !(minus9dir[KingSQ(enemy)] & checkers))
        blockers &= ~minus9dir[KingSQ(enemy)];
*/
/*
 ************************************************************
 *                                                          *
 *   Knight discovered checks.                              *
 *                                                          *
 ************************************************************
 */
/*      target = ~OccupiedSquares;
      temp_target = target & ~knight_attacks[KingSQ(enemy)];
      for (piecebd = Knights(side) & blockers; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = knight_attacks[from] & temp_target;
        temp = from + (knight << 12);
        Unpack(side, move, moves, temp);
      }
*/      
/*
 ************************************************************
 *                                                          *
 *   Rook discovered checks.                                *
 *                                                          *
 ************************************************************
 */
/*      target = ~OccupiedSquares;
      temp_target = target & ~AttacksRook(KingSQ(enemy), OccupiedSquares);
      for (piecebd = Rooks(side) & blockers; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksRook(from, OccupiedSquares) & temp_target;
        temp = from + (rook << 12);
        Unpack(side, move, moves, temp);
      }
*/
/*
 ************************************************************
 *                                                          *
 *   Pawn discovered checks.                                *
 *                                                          *
 ************************************************************
 */
/*      piecebd =
          Pawns(side) & blockers & ((side) ? ~OccupiedSquares >> 8 :
          ~OccupiedSquares << 8);
      for (; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        to = from + pawnadv1[enemy];
        if ((side) ? to > 55 : to < 8)
          promote = queen;
        else
          promote = 0;
        *move++ = from | (to << 6) | (pawn << 12) | (promote << 18);
      }
    }
  }
*/  
/*
 ************************************************************
 *                                                          *
 *   Next, we look for rank/file discovered attacks.  Once  *
 *   we know which squares hold pieces that create a        *
 *   discovered check when they move, we generate them      *
 *   piece type by piece type.                              *
 *                                                          *
 ************************************************************
 */
/*  blockers =
      AttacksRook(KingSQ(enemy),
      OccupiedSquares) & (Bishops(side) | Knights(side) | (Pawns(side) &
          rank_mask[Rank(KingSQ(enemy))]));
  if (blockers) {
    checkers =
        AttacksRook(KingSQ(enemy),
        OccupiedSquares & ~blockers) & (Rooks(side) | Queens(side));
    if (checkers) {
      if ((plus1dir[KingSQ(enemy)] & blockers)
          && !(plus1dir[KingSQ(enemy)] & checkers))
        blockers &= ~plus1dir[KingSQ(enemy)];
      if ((plus8dir[KingSQ(enemy)] & blockers)
          && !(plus8dir[KingSQ(enemy)] & checkers))
        blockers &= ~plus8dir[KingSQ(enemy)];
      if ((minus1dir[KingSQ(enemy)] & blockers)
          && !(minus1dir[KingSQ(enemy)] & checkers))
        blockers &= ~minus1dir[KingSQ(enemy)];
      if ((minus8dir[KingSQ(enemy)] & blockers)
          && !(minus8dir[KingSQ(enemy)] & checkers))
        blockers &= ~minus8dir[KingSQ(enemy)];
*/        
/*
 ************************************************************
 *                                                          *
 *   Knight discovered checks.                              *
 *                                                          *
 ************************************************************
 */
/*      target = ~OccupiedSquares;
      temp_target = target & ~knight_attacks[KingSQ(enemy)];
      for (piecebd = Knights(side) & blockers; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = knight_attacks[from] & temp_target;
        temp = from + (knight << 12);
        Unpack(side, move, moves, temp);
      }
*/      
/*
 ************************************************************
 *                                                          *
 *   Bishop discovered checks.                              *
 *                                                          *
 ************************************************************
 */
/*      target = ~OccupiedSquares;
      temp_target = target & ~AttacksBishop(KingSQ(enemy), OccupiedSquares);
      for (piecebd = Bishops(side) & blockers; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        moves = AttacksBishop(from, OccupiedSquares) & temp_target;
        temp = from + (bishop << 12);
        Unpack(side, move, moves, temp);
      }
*/      
/*
 ************************************************************
 *                                                          *
 *   Pawn discovered checks.                                *
 *                                                          *
 ************************************************************
 */
/*      piecebd =
          Pawns(side) & blockers & ((side) ? ~OccupiedSquares >> 8 :
          ~OccupiedSquares << 8);
      for (; piecebd; Clear(from, piecebd)) {
        from = Advanced(side, piecebd);
        to = from + pawnadv1[enemy];
        if ((side) ? to > 55 : to < 8)
          promote = queen;
        else
          promote = 0;
        *move++ = from | (to << 6) | (pawn << 12) | (promote << 18);
      }
    }
  }
*/  
  return (num_moves);
}