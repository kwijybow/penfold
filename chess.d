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
int[string] squarenum;
string[int] squarename;
int lower_b = 10;
int mobility_score_b[4] = [ 1, 2, 3, 4 ];
int mobility_score_r[4] = [ 1, 2, 3, 4 ];
int mob_curve_r[48] = [
  -27,-23,-21,-19,-15,-10, -9, -8,
   -7, -6, -5, -4, -3, -2, -1,  0,
    1,  2,  3,  4,  5,  6,  7,  8,
    9, 10, 11, 12, 13, 14, 15, 16,
   17, 18, 19, 20, 21, 22, 23, 24,
   25, 26, 27, 28, 29, 30, 31, 32
];
int pawnadv1[2] = [ +8, -8 ];
int capleft[2] = [ +9, -7 ];
int capright[2] = [ +7, -9 ];
int pawnadv2[2] = [ +16, -16 ];


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

ulong SetMask(int a) {
    return(set_mask[a]);
}


int Advanced(int side, ulong bitboard) {
    int b = 0;
    if (side == Color.white) 
        b = bsr(bitboard);
    else
        b = bsf(bitboard);
    return (b);   
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
    squarenum["-"] = BAD_SQUARE;
    squarename[BAD_SQUARE] = "-";
}