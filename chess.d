import std.math;
import core.bitop;
import masks;

immutable MATE = 32768;
immutable MAXPLY = 129;
immutable BAD_SQUARE = 64;

immutable UPPER = 2;
immutable AVOID_NULL_MOVE = 2;
immutable EXACT = 3;
immutable HASH_HIT = 1;
immutable LOWER = 1;
immutable HASH_MISS = 0;
immutable MAX_DRAFT = 256;
int null_depth = 3;
int iteration_depth = 0;
int move_list[5120];
int[string] squarenum;
string[int] squarename;

struct Path {
  int path[MAXPLY];
  ubyte pathh;
  ubyte pathl;
  ubyte pathd;
};

enum Color { white = 0, black = 1 };
enum Piece { pawn = 1, knight = 2, bishop = 3, rook = 4, queen = 5, king = 6 };
enum Castle { none = 0, king = 1, queen = 2, both = 3 }
    
int Flip(int x) {
    return ((x)^1);
}

ulong ClearMask(int a) {
    return (clear_mask[a]);
}

void Clear(int a, ref ulong b) {
    b &= ClearMask(a);
}

int Advanced (int side ulong bitboard) {
    int b = 0;
    if (side == Color.white) 
        b = bsr(bitboard);
    else
        b = bsf(bitboard);
    return b;   
}

void Unpack (int side, ref int mptr, ulong m, int t) {
  int to;
  for ( ; m ; Clear(to, m)) {
    to = Advanced(side, m);       
    *mptr++ = t | (to << 6) | (abs(PcOnSq(to)) << 15);
  }
}  
    
void InitializeSquares() {
    int square = 0;
    string square_by_name;
            
    foreach(row; ["1","2","3","4","5","6","7","8"]) {
        foreach(col; ["h","g","f","e","d","c","b","a"]) {
            square_by_name = col ~ row;
            squarenum[square_by_name] = square;
            squarename[square] = square_by_name;
            square++;
        }
    }
}