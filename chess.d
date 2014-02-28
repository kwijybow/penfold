immutable MATE = 32768;
immutable MAXPLY = 129;

immutable UPPER = 2;
immutable AVOID_NULL_MOVE = 2;
immutable EXACT = 3;
immutable HASH_HIT = 1;
immutable LOWER = 1;
immutable HASH_MISS = 0;
immutable MAX_DRAFT = 256;
int null_depth = 3;
int iteration_depth = 0;

struct Path {
  int path[MAXPLY];
  ubyte pathh;
  ubyte pathl;
  ubyte pathd;
};

enum Color { white = 0, black = 1 };
enum Piece { pawn = 1, knight = 2, bishop = 3, rook = 4, queen = 5, king = 6 };
enum Castle { none = 0, king = 1, queen = 2, both = 3 }
    

