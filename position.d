import std.stdio, std.string, std.array, std.conv;
import core.bitop;

class Position {
    enum Color { white = 0, black = 1 };
    enum Piece { pawn = 1, knight = 2, bishop = 3, rook = 4, queen = 5, king = 6 };
    enum Castle { none = 0, king = 1, queen = 2, both = 3 }
    
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
    Castle wcastle;
    Castle bcastle;
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
        enpassant_target = "-";
        wcastle = Castle.none;
        bcastle = Castle.none;
        
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
        move_number  = 0;
        draw_moves   = 0;
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
                  switch (tboard[i]) {
                      case -1:
                          dropPiece(Color.black, Piece.pawn, squarename[i]);
                          break;
                      case 1:
                          dropPiece(Color.white, Piece.pawn, squarename[i]);
                          break;
                      case -2:
                          dropPiece(Color.black, Piece.knight, squarename[i]);
                          break;
                      case 2:
                          dropPiece(Color.white, Piece.knight, squarename[i]);
                          break;
                      case -3:
                          dropPiece(Color.black, Piece.bishop, squarename[i]);
                          break;
                      case 3:
                          dropPiece(Color.white, Piece.bishop, squarename[i]);
                          break;
                      case -4:
                          dropPiece(Color.black, Piece.rook, squarename[i]);
                          break;
                      case 4:
                          dropPiece(Color.white, Piece.rook, squarename[i]);
                          break;
                      case -5:
                          dropPiece(Color.black, Piece.queen, squarename[i]);
                          break;
                      case 5:
                          dropPiece(Color.white, Piece.queen, squarename[i]);
                          break;
                      case -6:
                          dropPiece(Color.black, Piece.king, squarename[i]);
                          break;
                      case 6:
		          dropPiece(Color.white, Piece.king, squarename[i]);
		          break;
		      default:
		          break;
		  }
		  updateOccupied();
              }
              ctm = twtm;
              bcastle = black_castle;
              wcastle = white_castle;
              draw_moves = dm;
              move_number = mv;
              enpassant_target = ep.dup;
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

          //writefln("%s",fenstring);
     
         return ok;
    } 
}