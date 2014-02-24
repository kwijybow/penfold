import std.stdio, std.string, std.array;
import core.bitop;

class Position {
    enum Color { white = 0, black = 1 };
    enum Piece { pawn = 1, knight = 2, bishop = 3, rook = 4, queen = 5, king = 6 };
    
    Color ctm;
    ulong whitepawns;
    ulong whiterooks;
    ulong whiteknights;
    ulong whitebishops;
    ulong whitequeens;
    ulong whiteking;
    ulong blackpawns;
    ulong blackrooks;
    ulong blackknights;
    ulong blackbishops;
    ulong blackqueens;
    ulong blackking;
    ulong occupied;
    ulong empty;
    int move_number;
    int draw_moves;
    bool[string] castle;
    string enpassant_target;
    int[string] squarenum;
    string[int] squarename;
    string displayBoard[64];
    
    
    
    this() {
        int square = 0;
        string square_by_name;
        
        whitepawns   = 0;
        whiterooks   = 0;
        whiteknights = 0;
        whitebishops = 0;
        whitequeens  = 0;
        whiteking    = 0;
        blackpawns   = 0;
        blackrooks   = 0;
        blackknights = 0;
        blackbishops = 0;
        blackqueens  = 0;
        blackking    = 0;
        occupied     = 0;
        empty        = ~occupied;
        move_number  = 0;
        draw_moves   = 0;
        enpassant_target = "";
        castle["K"] = true;
        castle["Q"] = true;
        castle["k"] = true;
        castle["q"] = true;

        
        foreach(row; ["1","2","3","4","5","6","7","8"]) {
            foreach(col; ["h","g","f","e","d","c","b","a"]) {
                square_by_name = col ~ row;
                squarenum[square_by_name] = square;
                squarename[square] = square_by_name;
                square++;
            }
        }
    }
    
    void updateDisplayBoard() {
        ulong tempBoard = 0;
        int sq;
        
        for(int i=0; i<64; i++)
            displayBoard[i] = " ".dup;
        tempBoard = blackpawns;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "p".dup;
        }
        tempBoard = whitepawns;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "P".dup;
        }
        tempBoard = blackrooks;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "r".dup;
        }
        tempBoard = whiterooks;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "R".dup;
        }
        tempBoard = blackknights;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "n".dup;
        }
        tempBoard = whiteknights;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "N".dup;
        }
        tempBoard = blackbishops;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "b".dup;
        }
        tempBoard = whitebishops;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "B".dup;
        }
        tempBoard = blackqueens;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "q".dup;
        }
        tempBoard = whitequeens;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "Q".dup;
        }
        tempBoard = blackking;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "k".dup;
        }
        tempBoard = whiteking;
        while (tempBoard) {
            sq = bsf(tempBoard);
            tempBoard &= tempBoard - 1;
            displayBoard[sq] = "K".dup;
        }
    }

    void updateOccupied() {
        occupied = 0;
        occupied |= (blackpawns | whitepawns);
        occupied |= (blackrooks | whiterooks);
        occupied |= (blackknights | whiteknights);
        occupied |= (blackbishops | whitebishops);
        occupied |= (blackqueens | whitequeens);
        occupied |= (blackking | whiteking);
        empty = ~occupied;
    }
    
    void dropPiece (Color color, Piece piece, string square) {
        ulong one = 1;
        
        switch (piece) {
            case Piece.pawn:
                if (color == Color.black)
                    blackpawns |= (one << squarenum[square]);
                else
                    whitepawns |= (one << squarenum[square]);
                break;
            case Piece.rook:
                if (color == Color.black)
                    blackrooks |= (one << squarenum[square]);
                else
                    whiterooks |= (one << squarenum[square]);
                break;
            case Piece.knight:
                if (color == Color.black)
                    blackknights |= (one << squarenum[square]);
                else
                    whiteknights |= (one << squarenum[square]);
                break;
            case Piece.bishop:
                if (color == Color.black)
                    blackbishops |= (one << squarenum[square]);
                else
                    whitebishops |= (one << squarenum[square]);
                break;
            case Piece.queen:
                if (color == Color.black)
                    blackqueens |= (one << squarenum[square]);
                else
                    whitequeens |= (one << squarenum[square]);
                break;
            case Piece.king:
                if (color == Color.black)
                    blackking |= (one << squarenum[square]);
                else
                    whiteking |= (one << squarenum[square]);
                break;
            default:
                break;
        }
        updateOccupied();
    }
    
    void clearPosition() {
        whitepawns   = 0;
        whiterooks   = 0;
        whiteknights = 0;
        whitebishops = 0;
        whitequeens  = 0;
        whiteking    = 0;
        blackpawns   = 0;
        blackrooks   = 0;
        blackknights = 0;
        blackbishops = 0;
        blackqueens  = 0;
        blackking    = 0;
        occupied     = 0;
        empty        = ~occupied;
    }        
    
    void startPosition() {
        string whitesquare;
        string blacksquare;
    
        clearPosition();   
        foreach(col; ["a","b","c","d","e","f","g","h"]) {
            whitesquare = col ~ "2";
            blacksquare = col ~ "7";
            dropPiece(Color.white, Piece.pawn, whitesquare);
            dropPiece(Color.black, Piece.pawn, blacksquare);
        }
        
        dropPiece(Color.white, Piece.rook,   "a1");
        dropPiece(Color.white, Piece.rook,   "h1");
        dropPiece(Color.white, Piece.knight, "b1");
        dropPiece(Color.white, Piece.knight, "g1");
        dropPiece(Color.white, Piece.bishop, "c1");
        dropPiece(Color.white, Piece.bishop, "f1");
        dropPiece(Color.white, Piece.queen,  "d1");
        dropPiece(Color.white, Piece.king,   "e1");
 
        dropPiece(Color.black, Piece.rook,   "a8");
        dropPiece(Color.black, Piece.rook,   "h8");
        dropPiece(Color.black, Piece.knight, "b8");
        dropPiece(Color.black, Piece.knight, "g8");
        dropPiece(Color.black, Piece.bishop, "c8");
        dropPiece(Color.black, Piece.bishop, "f8");
        dropPiece(Color.black, Piece.queen,  "d8");
        dropPiece(Color.black, Piece.king,   "e8");

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
    }
    
    void printBitBoard(ulong board) {
        int i, j, x;

        writeln;
        for (i = 56; i >= 0; i -= 8) {
            x = (board >> i) & 255;
            for (j = 1; j < 256; j = j << 1)
                if (x & j)
                    writef("X ");
                else
                    writef("- ");
            writef("\n");
        }
        writeln;
    }
    
    bool setFEN(string fenstring) {
          int twtm, i, match, num, pos, square;
          int tboard[64];
          int bcastle, ep, wcastle, error = 0;
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
                          error = 1;
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
                          error = 1;
                          break;
                      }
                      tboard[square++] = match - 6;
                  }
          }
          twtm = 0;
          ep = 0;
          wcastle = 0;
          bcastle = 0;
          
          pos++;
          
          if (fenstring[pos] == 'w')
              twtm = 1;
          else if (fenstring[pos] == 'b')
              twtm = 0;
          else {
              writeln("side to move is bad");
              error = 1;
          }
          
          pos += 2;
          
          for (; pos < fenstring.length; pos++) {
              for (match = 0; ((match < 14) && (fenstring[pos] != status[match])); match++) {};
                  if (match > 12)
                      break;
                  if (match == 12) {
                      castle["K"] = false;
                      castle["Q"] = false;
                      castle["k"] = false;
                      castle["q"] = false;
                  }    
                  else if (match == 0)
                      castle["K"] = true;
                  else if (match == 1)
                      castle["Q"] = true;
                  else if (match == 2)
                      castle["k"] = true;
                  else if (match == 3)
                      castle["q"] = true;    
                  else {
                      writeln("castling status is bad.");
                      error = 1;
                  }          
          }
          
          pos++;
          
          if (fenstring[pos] == '-') {
              enpassant_target = "";
              pos += 2;
          }    
          else if (fenstring.length > pos+2) 
              if (fenstring[pos] >= 'a' && fenstring[pos] <= 'h' && fenstring[pos+1] > '0' && fenstring[pos+1] < '9') {
                  enpassant_target = fenstring[pos .. (pos+2)].dup;
                  pos += 3;
              }    
              else {
                  writeln("enpassant status is bad.");
                  error = 1;
              }
          else {
              writeln("enpassant status is bad.");
              error = 1;
          }

          
          
          writeln("pos = ",pos);
          for(i=pos; i<fenstring.length; i++)  
              writeln("fenstring[pos] = ",fenstring[i]);
          
          return ok;
    }
}