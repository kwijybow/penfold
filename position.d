import std.stdio, std.string, std.array, std.conv;
import core.bitop;
import hash;
import chess;

class Position {
    
    Color ctm;
    ulong pawns[2];
    ulong rooks[2];
    ulong knights[2];
    ulong bishops[2];
    ulong queens[2];
    ulong kings[2];
    ulong occupied[2];
    ulong empty;
    ulong hash_key;
    ulong pawn_hash_key;
    int move_number;
    int draw_moves;
    Castle wcastle;
    Castle bcastle;
    string enpassant_target;
    string displayBoard[64];
    
    this() {
        int square = 0;
        string square_by_name;
        
        for (int i=0; i<2; i++) {
            pawns[i]    = 0;
            rooks[i]    = 0;
            knights[i]  = 0;
            bishops[i]  = 0;
            queens[i]   = 0;
            kings[i]    = 0;
            occupied[i] = 0;
        }
        empty         = ~(occupied[0] | occupied[1]);
        hash_key      = 0;
        pawn_hash_key = 0;
        move_number   = 0;
        draw_moves    = 0;
        enpassant_target = "-";
        wcastle = Castle.none;
        bcastle = Castle.none;
        
        foreach(row; ["1","2","3","4","5","6","7","8"]) {
            foreach(col; ["h","g","f","e","d","c","b","a"]) {
                displayBoard[square] = " ".dup;
                square++;
            }
        }
    }
    
    void updateDisplayBoard() {
        ulong tempBoard = 0;
        int sq;
        
        for(int i=0; i<64; i++)
            displayBoard[i] = " ".dup;
        tempBoard = pawns[Color.black];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "p".dup;
        }
        tempBoard = pawns[Color.white];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "P".dup;
        }
        tempBoard = rooks[Color.black];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "r".dup;
        }
        tempBoard = rooks[Color.white];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "R".dup;
        }
        tempBoard = knights[Color.black];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "n".dup;
        }
        tempBoard = knights[Color.white];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "N".dup;
        }
        tempBoard = bishops[Color.black];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "b".dup;
        }
        tempBoard = bishops[Color.white];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "B".dup;
        }
        tempBoard = queens[Color.black];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "q".dup;
        }
        tempBoard = queens[Color.white];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "Q".dup;
        }
        tempBoard = kings[Color.black];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "k".dup;
        }
        tempBoard = kings[Color.white];
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "K".dup;
        }
    }

    void updateOccupied() {
        occupied[Color.white] = 0;
        occupied[Color.black] = 0;
        occupied[Color.white] |= pawns[Color.white];
        occupied[Color.white] |= rooks[Color.white];
        occupied[Color.white] |= knights[Color.white];
        occupied[Color.white] |= bishops[Color.white];
        occupied[Color.white] |= queens[Color.white];
        occupied[Color.white] |= kings[Color.white];
        occupied[Color.black] |= pawns[Color.black];
        occupied[Color.black] |= rooks[Color.black];
        occupied[Color.black] |= knights[Color.black];
        occupied[Color.black] |= bishops[Color.black];
        occupied[Color.black] |= queens[Color.black];
        occupied[Color.black] |= kings[Color.black];
        empty = ~(occupied[Color.white] | occupied[Color.black]);
    }
    
    void hashPiece(int color, int piece, int square) {
        hash_key ^= randoms[color][piece][square];
    }

    void hashPawn(int color, int square) {
        pawn_hash_key ^= randoms[color][Piece.pawn][square];
    }
    
    void hashCastle(int color, Castle castling) {
        if (castling == Castle.none)
            return;
        else if (castling == Castle.king)
            hash_key ^= castle_random[color][0];
        else if (castling == Castle.queen)
            hash_key ^= castle_random[color][1];
        else if (castling == Castle.both) {
            hash_key ^= castle_random[color][0];
            hash_key ^= castle_random[color][1];
        }    
    }
    
    void hashEnpassant(int square) {
        hash_key ^= enpassant_random[square];
    }
    
    void dropPiece (int color, int piece, string square) {
        ulong one = 1;
        
        switch (piece) {
            case Piece.pawn:
                pawns[color] |= (one << squarenum[square]);
                hashPawn(color, squarenum[square]);
                break;
            case Piece.rook:
                rooks[color] |= (one << squarenum[square]);
                break;
            case Piece.knight:
                knights[color] |= (one << squarenum[square]);
                break;
            case Piece.bishop:
                bishops[color] |= (one << squarenum[square]);
                break;
            case Piece.queen:
                queens[color] |= (one << squarenum[square]);
                break;
            case Piece.king:
                kings[color] |= (one << squarenum[square]);
                break;
            default:
                break;
        }
        hashPiece(color, piece, squarenum[square]);
        updateOccupied();
    }
    
    void clearPosition() {
    
        for (int i=0; i<2; i++) {
            pawns[i]    = 0;
            rooks[i]    = 0;
            knights[i]  = 0;
            bishops[i]  = 0;
            queens[i]   = 0;
            kings[i]    = 0;
            occupied[i] = 0;
        }
        empty         = ~(occupied[0] | occupied[1]); 
        hash_key      = 0;
        pawn_hash_key = 0;
        move_number   = 0;
        draw_moves    = 0;
        enpassant_target = "-";
        wcastle = Castle.none;
        bcastle = Castle.none;
    }        
    
    void startPosition() {

    clearPosition();
    setFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1".dup);
    
    }
   
    void printPosition() {
        int square;
        string square_by_name;
        
        updateDisplayBoard();
        
        writefln("     a   b   c   d   e   f   g   h     ");
        writefln("   +---+---+---+---+---+---+---+---+   ");
        foreach(row; ["8","7","6","5","4","3","2","1"]) {
            writef(" %s |", row);
            foreach(col; ["a","b","c","d","e","f","g","h"]) {
                square_by_name = col ~ row;
                writef(" %s |",displayBoard[squarenum[square_by_name]]);
            }
            writefln(" %s",row);
            writefln("   +---+---+---+---+---+---+---+---+   ");
        }
        writefln("     a   b   c   d   e   f   g   h     ");
        writeln;
        if (ctm == Color.white)
            writeln("white to move");
        else
            writeln("black to move");
        writefln("move number %s ", move_number);
        writefln("50 move rule count %s ", draw_moves);
        writefln("white castling = %s", wcastle);
        writefln("black castling = %s", bcastle);
        writefln("enpassant target = %s", enpassant_target);
        writefln("hash_key = %s", hash_key);
        writefln("pawn_hash_key = %s", pawn_hash_key);
    }  
    
    bool setFEN(char[] fenstring) {
          int i, match, num, pos, square;
          int dm, mv;
          int tboard[64];
          int a_rank[8];
          Color twtm;
          Castle black_castle, white_castle;
          char input[80];
          char bdinfo[] =   [ 'k', 'q', 'r', 'b', 'n', 'p', '*', 'P', 'N', 'B',
                              'R', 'Q', 'K', '*', '1', '2', '3', '4',
                              '5', '6', '7', '8', '/'
                            ];
          char status[14] = [ 'K', 'Q', 'k', 'q', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
                              'h', '-', ' '
                            ];
          int whichsq;
          int firstsq[8] = [ 56, 48, 40, 32, 24, 16, 8, 0 ];
          bool ok = true;
          string ep = "-";
          
          
          for (i = 0; i < 64; i++)
          tboard[i] = 0;
          
          whichsq = 0;
          square = firstsq[whichsq];
          num = 0;
          for (pos = 0; pos < fenstring.length; pos++) {
              for (match = 0; ((match < 23) && (fenstring[pos] != bdinfo[match])); match++) {};
                  if (match > 22)
                      break;
          /*
          "/" -> end of this rank.
          */
                  else if (match == 22) {
                      num = 0;
                      if (whichsq > 6)
                          break;
                      square = firstsq[++whichsq];
                  }
          /*
          "1-8" -> empty squares.
          */
                  else if (match >= 14) {
                      num += match - 13;
                      square += match - 13;
                      if (num > 8) {
                          writeln("more than 8 squares on one rank");
                          ok = false;
                          break;
                      }
                      continue;
                  }
          /*
          piece codes.
          */
                  else {
                      if (++num > 8) {
                          writeln("more than 8 squares on one rank");
                          ok = false;
                          break;
                      }
                      tboard[square++] = match - 6;
                  }
          }

          pos++;
          
          if (fenstring[pos] == 'w')
              twtm = Color.white;
          else if (fenstring[pos] == 'b')
              twtm = Color.black;
          else {
              writeln("side to move is bad");
              ok = false;
          }
          
          pos += 2;
          
          for (; pos < fenstring.length; pos++) {
              for (match = 0; ((match < 14) && (fenstring[pos] != status[match])); match++) {};
                  if (match > 12)
                      break;
                  if (match == 12) {
                      white_castle = Castle.none;
                      black_castle = Castle.none;
                  }    
                  else if (match == 0)
                      white_castle += 1;
                  else if (match == 1)
                      white_castle += 2;
                  else if (match == 2)
                      black_castle += 1;
                  else if (match == 3)
                      black_castle += 2;    
                  else {
                      writeln("castling status is bad.");
                      ok = false;
                  }          
          }
          
          pos++;
          
          if (fenstring[pos] == '-') {
              ep = "-";
              pos += 2;
          }    
          else if (fenstring.length > pos+2) 
              if (fenstring[pos] >= 'a' && fenstring[pos] <= 'h' && fenstring[pos+1] > '0' && fenstring[pos+1] < '9') {
                  ep = fenstring[pos .. (pos+2)].dup;
                  pos += 3;
              }    
              else {
                  writeln("enpassant status is bad.");
                  ok = false;
              }
          else {
              writeln("enpassant status is bad.");
              ok = false;
          }

          auto move_info = array(splitter(fenstring[pos .. $]));
          if (move_info.length == 2) {
              dm = to!int(move_info[0]);
              mv = to!int(move_info[1]);
          }
          else {
              writeln("move numbers are bad.");
              ok = false;
          }
          
          for (i=0; i<8; i++) {
              a_rank = tboard[firstsq[i] .. (firstsq[i]+8)];
              tboard[firstsq[i] .. (firstsq[i]+8)] = a_rank.reverse;
          }
          
          if (ok) {
              clearPosition();
              for (i=63; i>=0; i--) {
                  if (tboard[i] < 0) {
                      dropPiece(Color.black, -tboard[i], squarename[i]);
                  }
                  else if (tboard[i] > 0) {
                       dropPiece(Color.white, tboard[i], squarename[i]);
                  }
		  updateOccupied();
              }
              ctm = twtm;
              bcastle = black_castle;
              hashCastle(Color.black, bcastle);
              wcastle = white_castle;
              hashCastle(Color.white, wcastle);
              draw_moves = dm;
              move_number = mv;
              enpassant_target = ep.dup;
              if (enpassant_target != "-") 
                  hashEnpassant(squarenum[enpassant_target]);
          }    
          return ok;
    }
    
    bool getFEN(ref char[] fenstring) {
          int i, num;
          bool ok = true;
          string castle_status = "";
          
          fenstring.length = 0;
          updateDisplayBoard();
          num = 0;
          for (i=63; i>=0; i--) {
              if (displayBoard[i] == " ") 
                  num++;
              else {
                  if (num > 0) { 
                      fenstring = fenstring ~ to!string(num);
                      num = 0;
                  }
                  fenstring = fenstring ~ displayBoard[i];
              }
              if ((i % 8) == 0) {
                  if (num > 0) { 
                      fenstring = fenstring ~ to!string(num);
                      num = 0;
                  }
                  if (i > 0)
                      fenstring = fenstring ~ "/";
              }
          }
          
          fenstring = fenstring ~ " ";
          
          if (ctm == Color.white)
              fenstring = fenstring ~ "w";
          else 
              fenstring = fenstring ~ "b";
          
          fenstring = fenstring ~ " ";
          
          if (wcastle == Castle.both)
              castle_status = castle_status ~ "KQ";
          else if (wcastle == Castle.king)
              castle_status = castle_status ~ "K";
          else if (wcastle == Castle.queen)
              castle_status = castle_status ~ "Q";
              
          if (bcastle == Castle.both)
              castle_status = castle_status ~ "kq";
          else if (bcastle == Castle.king)
              castle_status = castle_status ~ "k";
          else if (bcastle == Castle.queen)
              castle_status = castle_status ~ "q";
              
          if (castle_status.length == 0) 
              castle_status = castle_status ~ "-";
              
          fenstring = fenstring ~ castle_status;
          fenstring = fenstring ~ " ";
          fenstring = fenstring ~ enpassant_target;
          fenstring = fenstring ~ " ";
          fenstring = fenstring ~ to!string(draw_moves);
          fenstring = fenstring ~ " ";
          fenstring = fenstring ~ to!string(move_number);
     
         return ok;
    } 
}