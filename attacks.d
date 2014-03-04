import std.stdio, std.string, std.array, std.conv;
import core.bitop;
import chess;
import masks;
import bitboard;



ulong magic_bishop[64] = [
  0x0002020202020200UL, 0x0002020202020000UL, 0x0004010202000000UL,
  0x0004040080000000UL, 0x0001104000000000UL, 0x0000821040000000UL,
  0x0000410410400000UL, 0x0000104104104000UL, 0x0000040404040400UL,
  0x0000020202020200UL, 0x0000040102020000UL, 0x0000040400800000UL,
  0x0000011040000000UL, 0x0000008210400000UL, 0x0000004104104000UL,
  0x0000002082082000UL, 0x0004000808080800UL, 0x0002000404040400UL,
  0x0001000202020200UL, 0x0000800802004000UL, 0x0000800400A00000UL,
  0x0000200100884000UL, 0x0000400082082000UL, 0x0000200041041000UL,
  0x0002080010101000UL, 0x0001040008080800UL, 0x0000208004010400UL,
  0x0000404004010200UL, 0x0000840000802000UL, 0x0000404002011000UL,
  0x0000808001041000UL, 0x0000404000820800UL, 0x0001041000202000UL,
  0x0000820800101000UL, 0x0000104400080800UL, 0x0000020080080080UL,
  0x0000404040040100UL, 0x0000808100020100UL, 0x0001010100020800UL,
  0x0000808080010400UL, 0x0000820820004000UL, 0x0000410410002000UL,
  0x0000082088001000UL, 0x0000002011000800UL, 0x0000080100400400UL,
  0x0001010101000200UL, 0x0002020202000400UL, 0x0001010101000200UL,
  0x0000410410400000UL, 0x0000208208200000UL, 0x0000002084100000UL,
  0x0000000020880000UL, 0x0000001002020000UL, 0x0000040408020000UL,
  0x0004040404040000UL, 0x0002020202020000UL, 0x0000104104104000UL,
  0x0000002082082000UL, 0x0000000020841000UL, 0x0000000000208800UL,
  0x0000000010020200UL, 0x0000000404080200UL, 0x0000040404040400UL,
  0x0002020202020200UL
];
ulong magic_bishop_mask[64] = [
  0x0040201008040200UL, 0x0000402010080400UL, 0x0000004020100A00UL,
  0x0000000040221400UL, 0x0000000002442800UL, 0x0000000204085000UL,
  0x0000020408102000UL, 0x0002040810204000UL, 0x0020100804020000UL,
  0x0040201008040000UL, 0x00004020100A0000UL, 0x0000004022140000UL,
  0x0000000244280000UL, 0x0000020408500000UL, 0x0002040810200000UL,
  0x0004081020400000UL, 0x0010080402000200UL, 0x0020100804000400UL,
  0x004020100A000A00UL, 0x0000402214001400UL, 0x0000024428002800UL,
  0x0002040850005000UL, 0x0004081020002000UL, 0x0008102040004000UL,
  0x0008040200020400UL, 0x0010080400040800UL, 0x0020100A000A1000UL,
  0x0040221400142200UL, 0x0002442800284400UL, 0x0004085000500800UL,
  0x0008102000201000UL, 0x0010204000402000UL, 0x0004020002040800UL,
  0x0008040004081000UL, 0x00100A000A102000UL, 0x0022140014224000UL,
  0x0044280028440200UL, 0x0008500050080400UL, 0x0010200020100800UL,
  0x0020400040201000UL, 0x0002000204081000UL, 0x0004000408102000UL,
  0x000A000A10204000UL, 0x0014001422400000UL, 0x0028002844020000UL,
  0x0050005008040200UL, 0x0020002010080400UL, 0x0040004020100800UL,
  0x0000020408102000UL, 0x0000040810204000UL, 0x00000A1020400000UL,
  0x0000142240000000UL, 0x0000284402000000UL, 0x0000500804020000UL,
  0x0000201008040200UL, 0x0000402010080400UL, 0x0002040810204000UL,
  0x0004081020400000UL, 0x000A102040000000UL, 0x0014224000000000UL,
  0x0028440200000000UL, 0x0050080402000000UL, 0x0020100804020000UL,
  0x0040201008040200UL
];
uint magic_bishop_shift[64] = [
  58, 59, 59, 59, 59, 59, 59, 58,
  59, 59, 59, 59, 59, 59, 59, 59,
  59, 59, 57, 57, 57, 57, 59, 59,
  59, 59, 57, 55, 55, 57, 59, 59,
  59, 59, 57, 55, 55, 57, 59, 59,
  59, 59, 57, 57, 57, 57, 59, 59,
  59, 59, 59, 59, 59, 59, 59, 59,
  58, 59, 59, 59, 59, 59, 59, 58
];
ulong magic_bishop_table[5248] = [0];
int magic_bishop_indices[64] = [
  4992, 2624,
  256, 896,
  1280, 1664,
  4800, 5120,
  2560, 2656,
  288, 928,
  1312, 1696,
  4832, 4928,
  0, 128,
  320, 960,
  1344, 1728,
  2304, 2432,
  32, 160,
  448, 2752,
  3776, 1856,
  2336, 2464,
  64, 192,
  576, 3264,
  4288, 1984,
  2368, 2496,
  96, 224,
  704, 1088,
  1472, 2112,
  2400, 2528,
  2592, 2688,
  832, 1216,
  1600, 2240,
  4864, 4960,
  5056, 2720,
  864, 1248,
  1632, 2272,
  4896, 5184
];
short magic_bishop_mobility_table[5248];
int magic_bishop_mobility_indices[64] = [
  4992, 2624,
  256, 896,
  1280, 1664,
  4800, 5120,
  2560, 2656,
  288, 928,
  1312, 1696,
  4832, 4928,
  0, 128,
  320, 960,
  1344, 1728,
  2304, 2432,
  32, 160,
  448, 2752,
  3776, 1856,
  2336, 2464,
  64, 192,
  576, 3264,
  4288, 1984,
  2368, 2496,
  96, 224,
  704, 1088,
  1472, 2112,
  2400, 2528,
  2592, 2688,
  832, 1216,
  1600, 2240,
  4864, 4960,
  5056, 2720,
  864, 1248,
  1632, 2272,
  4896, 5184
];
ulong magic_rook_table[102400];
int magic_rook_indices[64] = [
  86016, 73728,
  36864, 43008,
  47104, 51200,
  77824, 94208,
  69632, 32768,
  38912, 10240,
  14336, 53248,
  57344, 81920,
  24576, 33792,
  6144, 11264,
  15360, 18432,
  58368, 61440,
  26624, 4096,
  7168, 0,
  2048, 19456,
  22528, 63488,
  28672, 5120,
  8192, 1024,
  3072, 20480,
  23552, 65536,
  30720, 34816,
  9216, 12288,
  16384, 21504,
  59392, 67584,
  71680, 35840,
  39936, 13312,
  17408, 54272,
  60416, 83968,
  90112, 75776,
  40960, 45056,
  49152, 55296,
  79872, 98304
];
short magic_rook_mobility_table[102400];
int magic_rook_mobility_indices[64] = [
  86016, 73728,
  36864, 43008,
  47104, 51200,
  77824, 94208,
  69632, 32768,
  38912, 10240,
  14336, 53248,
  57344, 81920,
  24576, 33792,
  6144, 11264,
  15360, 18432,
  58368, 61440,
  26624, 4096,
  7168, 0,
  2048, 19456,
  22528, 63488,
  28672, 5120,
  8192, 1024,
  3072, 20480,
  23552, 65536,
  30720, 34816,
  9216, 12288,
  16384, 21504,
  59392, 67584,
  71680, 35840,
  39936, 13312,
  17408, 54272,
  60416, 83968,
  90112, 75776,
  40960, 45056,
  49152, 55296,
  79872, 98304
];
ulong magic_rook[64] = [
  0x0080001020400080UL, 0x0040001000200040UL, 0x0080081000200080UL,
  0x0080040800100080UL, 0x0080020400080080UL, 0x0080010200040080UL,
  0x0080008001000200UL, 0x0080002040800100UL, 0x0000800020400080UL,
  0x0000400020005000UL, 0x0000801000200080UL, 0x0000800800100080UL,
  0x0000800400080080UL, 0x0000800200040080UL, 0x0000800100020080UL,
  0x0000800040800100UL, 0x0000208000400080UL, 0x0000404000201000UL,
  0x0000808010002000UL, 0x0000808008001000UL, 0x0000808004000800UL,
  0x0000808002000400UL, 0x0000010100020004UL, 0x0000020000408104UL,
  0x0000208080004000UL, 0x0000200040005000UL, 0x0000100080200080UL,
  0x0000080080100080UL, 0x0000040080080080UL, 0x0000020080040080UL,
  0x0000010080800200UL, 0x0000800080004100UL, 0x0000204000800080UL,
  0x0000200040401000UL, 0x0000100080802000UL, 0x0000080080801000UL,
  0x0000040080800800UL, 0x0000020080800400UL, 0x0000020001010004UL,
  0x0000800040800100UL, 0x0000204000808000UL, 0x0000200040008080UL,
  0x0000100020008080UL, 0x0000080010008080UL, 0x0000040008008080UL,
  0x0000020004008080UL, 0x0000010002008080UL, 0x0000004081020004UL,
  0x0000204000800080UL, 0x0000200040008080UL, 0x0000100020008080UL,
  0x0000080010008080UL, 0x0000040008008080UL, 0x0000020004008080UL,
  0x0000800100020080UL, 0x0000800041000080UL, 0x00FFFCDDFCED714AUL,
  0x007FFCDDFCED714AUL, 0x003FFFCDFFD88096UL, 0x0000040810002101UL,
  0x0001000204080011UL, 0x0001000204000801UL, 0x0001000082000401UL,
  0x0001FFFAABFAD1A2UL
];
ulong magic_rook_mask[64] = [
  0x000101010101017EUL, 0x000202020202027CUL, 0x000404040404047AUL,
  0x0008080808080876UL, 0x001010101010106EUL, 0x002020202020205EUL,
  0x004040404040403EUL, 0x008080808080807EUL, 0x0001010101017E00UL,
  0x0002020202027C00UL, 0x0004040404047A00UL, 0x0008080808087600UL,
  0x0010101010106E00UL, 0x0020202020205E00UL, 0x0040404040403E00UL,
  0x0080808080807E00UL, 0x00010101017E0100UL, 0x00020202027C0200UL,
  0x00040404047A0400UL, 0x0008080808760800UL, 0x00101010106E1000UL,
  0x00202020205E2000UL, 0x00404040403E4000UL, 0x00808080807E8000UL,
  0x000101017E010100UL, 0x000202027C020200UL, 0x000404047A040400UL,
  0x0008080876080800UL, 0x001010106E101000UL, 0x002020205E202000UL,
  0x004040403E404000UL, 0x008080807E808000UL, 0x0001017E01010100UL,
  0x0002027C02020200UL, 0x0004047A04040400UL, 0x0008087608080800UL,
  0x0010106E10101000UL, 0x0020205E20202000UL, 0x0040403E40404000UL,
  0x0080807E80808000UL, 0x00017E0101010100UL, 0x00027C0202020200UL,
  0x00047A0404040400UL, 0x0008760808080800UL, 0x00106E1010101000UL,
  0x00205E2020202000UL, 0x00403E4040404000UL, 0x00807E8080808000UL,
  0x007E010101010100UL, 0x007C020202020200UL, 0x007A040404040400UL,
  0x0076080808080800UL, 0x006E101010101000UL, 0x005E202020202000UL,
  0x003E404040404000UL, 0x007E808080808000UL, 0x7E01010101010100UL,
  0x7C02020202020200UL, 0x7A04040404040400UL, 0x7608080808080800UL,
  0x6E10101010101000UL, 0x5E20202020202000UL, 0x3E40404040404000UL,
  0x7E80808080808000UL
];
uint magic_rook_shift[64] = [
  52, 53, 53, 53, 53, 53, 53, 52,
  53, 54, 54, 54, 54, 54, 54, 53,
  53, 54, 54, 54, 54, 54, 54, 53,
  53, 54, 54, 54, 54, 54, 54, 53,
  53, 54, 54, 54, 54, 54, 54, 53,
  53, 54, 54, 54, 54, 54, 54, 53,
  53, 54, 54, 54, 54, 54, 54, 53,
  53, 54, 54, 53, 53, 53, 53, 53
];
ulong mobility_mask_n[4] = [
  0xFF818181818181FFUL, 0x007E424242427E00UL,
  0x00003C24243C0000UL, 0x0000001818000000UL
];
ulong mobility_mask_b[4] = [
  0xFF818181818181FFUL, 0x007E424242427E00UL,
  0x00003C24243C0000UL, 0x0000001818000000UL
];
ulong mobility_mask_r[4] = [
  0x8181818181818181UL, 0x4242424242424242UL,
  0x2424242424242424UL, 0x1818181818181818UL
];


ulong knight_attacks[64];
ulong bishop_attacks[64];
ulong rook_attacks[64];
ulong queen_attacks[64];
ulong king_attacks[64];
ulong pawn_attacks[2][64];

ulong genKightAttack(int sq) {
    ulong from_board = to!ulong(1) << sq;
    ulong to_board = 0;
    
    to_board |= (from_board << 10) & (~(filemask_by_name["g"] | filemask_by_name["h"] | rankmask_by_name["1"]));
    to_board |= (from_board << 17) & (~(filemask_by_name["h"] | rankmask_by_name["1"] | rankmask_by_name["2"]));
    to_board |= (from_board << 15) & (~(filemask_by_name["a"] | rankmask_by_name["1"] | rankmask_by_name["2"]));
    to_board |= (from_board <<  6) & (~(filemask_by_name["a"] | filemask_by_name["b"] | rankmask_by_name["1"]));
    to_board |= (from_board >> 10) & (~(filemask_by_name["a"] | filemask_by_name["b"] | rankmask_by_name["8"]));
    to_board |= (from_board >> 17) & (~(filemask_by_name["a"] | rankmask_by_name["7"] | rankmask_by_name["8"]));
    to_board |= (from_board >> 15) & (~(filemask_by_name["h"] | rankmask_by_name["7"] | rankmask_by_name["8"]));
    to_board |= (from_board >>  6) & (~(filemask_by_name["g"] | filemask_by_name["h"] | rankmask_by_name["8"]));

    return (to_board);
}

ulong genBishopAttack(int sq) {
    ulong from_board = to!ulong(1) << sq;
    ulong flood;
    ulong gen;
    ulong pro;
  
    flood = gen = 0;
    gen = from_board;
    pro = ~gen & 0xfefefefefefefe00;
    while (gen) { 
        flood |= gen;
        gen = ((gen << 9) & pro);
    }
                        
    gen = from_board;
    pro = ~gen & 0x00fefefefefefefe;
    while (gen) {
        flood |= gen;
        gen = ((gen >> 7) & pro);
    }

    gen = from_board;
    pro = ~(gen) & 0x007f7f7f7f7f7f7f;
    while (gen) {
        flood |= gen;
        gen = ((gen >> 9) & pro);
    }

    gen = from_board;
    pro = ~gen & 0x7f7f7f7f7f7f7f00;
    while (gen) {
        flood |= gen;
        gen = ((gen << 7) & pro);
    }

    flood ^= from_board;
    return flood;
}

ulong genRookAttack(int sq) {
    ulong from_board = to!ulong(1) << sq;
    ulong flood;
    ulong gen;
    ulong pro;
  
    flood = gen = 0;
    gen = from_board;
    pro = ~gen & 0xfefefefefefefefe;
    while (gen) { 
        flood |= gen;
        gen = ((gen << 1) & pro);
    }
                        
    gen = from_board;
    pro = ~gen & 0x00ffffffffffffff;
    while (gen) {
        flood |= gen;
        gen = ((gen >> 8) & pro);
    }

    gen = from_board;
    pro = ~(gen) & 0x7f7f7f7f7f7f7f7f;
    while (gen) {
        flood |= gen;
        gen = ((gen >> 1) & pro);
    }

    gen = from_board;
    pro = ~gen & 0xffffffffffffff00;
    while (gen) {
        flood |= gen;
        gen = ((gen << 8) & pro);
    }

    flood ^= from_board;
    return flood;
}

ulong genKingAttack(int sq) {
    ulong from_board = to!ulong(1) << sq;
    ulong to_board = 0;

    ulong notH = 0xFEFEFEFEFEFEFEFE;
    ulong notA = 0x7F7F7F7F7F7F7F7F;
    to_board = from_board;
    to_board |= (to_board << 1) & notH;
    to_board |= (to_board << 8);
    to_board |= (to_board >> 1) & notA;
    to_board |= (to_board >> 8);
    to_board ^= from_board;
    return (to_board);
}

ulong genPawnAttack(Color color, int sq){
    ulong from_board = to!ulong(1) << sq;
    ulong to_board = 0;
    ulong notH = 0xFEFEFEFEFEFEFEFE;
    ulong notA = 0x7F7F7F7F7F7F7F7F;    
    ulong not1and2 = ~(rankmask_by_name["1"] | rankmask_by_name["2"]);
    ulong not7and8 = ~(rankmask_by_name["7"] | rankmask_by_name["8"]);
    to_board = from_board;
    
    if (color == Color.white) {
        to_board |= (from_board << 7) & (notA & not1and2);
        to_board |= (from_board << 9) & (notH & not1and2);
    }
    else {
        to_board |= (from_board >> 7) & (notH & not7and8);
        to_board |= (from_board >> 9) & (notA & not7and8);
    }    
    to_board ^= from_board;
    return(to_board);
}

void InitializeAttacks() {

    for (int i=0; i<64; i++) {
        knight_attacks[i] = genKightAttack(i);
        bishop_attacks[i] = genBishopAttack(i);
        rook_attacks[i]   = genRookAttack(i);
        queen_attacks[i]  = bishop_attacks[i] | rook_attacks[i];
        king_attacks[i]   = genKingAttack(i);
        pawn_attacks[Color.white][i] = genPawnAttack(Color.white, i);
        pawn_attacks[Color.black][i] = genPawnAttack(Color.black, i);
    }
}

/*
 *******************************************************************************
 *                                                                             *
 *   InitializeMagic() initializes the magic number tables used in the new     *
 *   magic move generation algorithm.  We also initialize a set of parallel    *
 *   tables that contain mobility scores for each possible set of magic attack *
 *   vectors, which saves significant time in the evaluation, since it is done *
 *   here before the game actually starts.                                     *
 *                                                                             *
 *******************************************************************************
 */
void InitializeMagic() {
  int i, j;
  int initmagicmoves_bitpos64_database[64] = [
    63, 0, 58, 1, 59, 47, 53, 2,
    60, 39, 48, 27, 54, 33, 42, 3,
    61, 51, 37, 40, 49, 18, 28, 20,
    55, 30, 34, 11, 43, 14, 22, 4,
    62, 57, 46, 52, 38, 26, 32, 41,
    50, 36, 17, 19, 29, 10, 13, 21,
    56, 45, 25, 31, 35, 16, 9, 12,
    44, 24, 15, 8, 23, 7, 6, 5
  ];
/*
 Bishop attacks and mobility
 */
  for (i = 0; i < 64; i++) {
    int squares[64];
    int numsquares = 0;
    ulong temp = magic_bishop_mask[i];

    while (temp) {
      ulong abit = temp & -temp;

      squares[numsquares++] =
          initmagicmoves_bitpos64_database[(abit *
              0x07EDD5E59A4E28C2UL) >> 58];
      temp ^= abit;
    }
    for (temp = 0; temp < ((to!ulong(1)) << numsquares); temp++) {
      ulong moves;
      int t = -lower_b;
      ulong tempoccupied = InitializeMagicOccupied(squares, numsquares, temp);
      moves = InitializeMagicBishop(i, tempoccupied);
      magic_bishop_table[(magic_bishop_indices[i] + (((tempoccupied) * magic_bishop[i]) >> magic_bishop_shift[i]))] = moves;
      moves |= SetMask(i);
      for (j = 0; j < 4; j++)
        t += PopCnt(moves & mobility_mask_b[j]) * mobility_score_b[j];
      if (t < 0)
        t *= 2;
        magic_bishop_mobility_table[(magic_bishop_mobility_indices[i] + (((tempoccupied) * magic_bishop[i]) >> magic_bishop_shift[i]))] = to!short(t);
    }
  }
/*
 Rook attacks and mobility
 */
  for (i = 0; i < 64; i++) {
    int squares[64];
    int numsquares = 0;
    int t;
    ulong temp = magic_rook_mask[i];

    while (temp) {
      ulong abit = temp & -temp;

      squares[numsquares++] =
          initmagicmoves_bitpos64_database[(abit *
              0x07EDD5E59A4E28C2UL) >> 58];
      temp ^= abit;
    }
    for (temp = 0; temp < ((to!ulong(1)) << numsquares); temp++) {
      ulong tempoccupied = InitializeMagicOccupied(squares, numsquares, temp);
      ulong moves = InitializeMagicRook(i, tempoccupied);
      magic_rook_table[(magic_rook_indices[i] + (((tempoccupied) * magic_rook[i]) >> magic_rook_shift[i]))] = moves;
      moves |= SetMask(i);
      t = -1;
      for (j = 0; j < 4; j++)
        t += PopCnt(moves & mobility_mask_r[j]) * mobility_score_r[j];
        magic_rook_mobility_table[(magic_rook_mobility_indices[i] + (((tempoccupied) * magic_rook[i]) >> magic_rook_shift[i]))] = to!short(mob_curve_r[t]);

    }
  }
}

ulong InitializeMagicBishop(int square, ulong occupied) {
  ulong ret = 0;
  ulong abit;
  ulong abit2;
  ulong rowbits = ((to!ulong(0xFF)) << (8 * (square / 8)));

  abit = ((to!ulong(1)) << square);
  abit2 = abit;
  do {
    abit <<= 8 - 1;
    abit2 >>= 1;
    if (abit2 & rowbits)
      ret |= abit;
    else
      break;
  } while (abit && !(abit & occupied));
  abit = ((to!ulong(1)) << square);
  abit2 = abit;
  do {
    abit <<= 8 + 1;
    abit2 <<= 1;
    if (abit2 & rowbits)
      ret |= abit;
    else
      break;
  } while (abit && !(abit & occupied));
  abit = ((to!ulong(1)) << square);
  abit2 = abit;
  do {
    abit >>= 8 - 1;
    abit2 <<= 1;
    if (abit2 & rowbits)
      ret |= abit;
    else
      break;
  } while (abit && !(abit & occupied));
  abit = ((to!ulong(1)) << square);
  abit2 = abit;
  do {
    abit >>= 8 + 1;
    abit2 >>= 1;
    if (abit2 & rowbits)
      ret |= abit;
    else
      break;
  } while (abit && !(abit & occupied));
  return (ret);
}

/*
 *******************************************************************************
 *                                                                             *
 *   InitializeMagicOccupied() generates a specific occupied-square bitboard   *
 *   needed during initialization.                                             *
 *                                                                             *
 *******************************************************************************
 */
ulong InitializeMagicOccupied(ref int squares[64], int numSquares, ulong linoccupied) {
  int i;
  ulong ret = 0;

  for (i = 0; i < numSquares; i++)
    if (linoccupied & ((to!ulong(1)) << i))
      ret |= ((to!ulong(1)) << squares[i]);
  return (ret);
}

/*
 *******************************************************************************
 *                                                                             *
 *   InitializeMagicRook() does the rook-specific initialization for a         *
 *   particular square on the board.                                           *
 *                                                                             *
 *******************************************************************************
 */
ulong InitializeMagicRook(int square, ulong occupied) {
  ulong ret = 0;
  ulong abit;
  ulong rowbits = ((to!ulong(0xFF)) << (8 * (square / 8)));

  abit = ((to!ulong(1)) << square);
  do {
    abit <<= 8;
    ret |= abit;
  } while (abit && !(abit & occupied));
  abit = ((to!ulong(1)) << square);
  do {
    abit >>= 8;
    ret |= abit;
  } while (abit && !(abit & occupied));
  abit = ((to!ulong(1)) << square);
  do {
    abit <<= 1;
    if (abit & rowbits)
      ret |= abit;
    else
      break;
  } while (!(abit & occupied));
  abit = ((to!ulong(1)) << square);
  do {
    abit >>= 1;
    if (abit & rowbits)
      ret |= abit;
    else
      break;
  } while (!(abit & occupied));
  return (ret);
}

ulong AttacksBishop(int square, ulong occ) {
    return(magic_bishop_table[(magic_bishop_indices[square]+((((occ)&magic_bishop_mask[square])*magic_bishop[square])>>magic_bishop_shift[square]))]);
}

