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

