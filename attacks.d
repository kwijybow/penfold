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
const ulong magic_bishop_table[5248] = [0];
const ulong *magic_bishop_indices[64] = [
  magic_bishop_table.ptr + 4992, magic_bishop_table.ptr + 2624,
  magic_bishop_table.ptr + 256, magic_bishop_table.ptr + 896,
  magic_bishop_table.ptr + 1280, magic_bishop_table.ptr + 1664,
  magic_bishop_table.ptr + 4800, magic_bishop_table.ptr + 5120,
  magic_bishop_table.ptr + 2560, magic_bishop_table.ptr + 2656,
  magic_bishop_table.ptr + 288, magic_bishop_table.ptr + 928,
  magic_bishop_table.ptr + 1312, magic_bishop_table.ptr + 1696,
  magic_bishop_table.ptr + 4832, magic_bishop_table.ptr + 4928,
  magic_bishop_table.ptr + 0, magic_bishop_table.ptr + 128,
  magic_bishop_table.ptr + 320, magic_bishop_table.ptr + 960,
  magic_bishop_table.ptr + 1344, magic_bishop_table.ptr + 1728,
  magic_bishop_table.ptr + 2304, magic_bishop_table.ptr + 2432,
  magic_bishop_table.ptr + 32, magic_bishop_table.ptr + 160,
  magic_bishop_table.ptr + 448, magic_bishop_table.ptr + 2752,
  magic_bishop_table.ptr + 3776, magic_bishop_table.ptr + 1856,
  magic_bishop_table.ptr + 2336, magic_bishop_table.ptr + 2464,
  magic_bishop_table.ptr + 64, magic_bishop_table.ptr + 192,
  magic_bishop_table.ptr + 576, magic_bishop_table.ptr + 3264,
  magic_bishop_table.ptr + 4288, magic_bishop_table.ptr + 1984,
  magic_bishop_table.ptr + 2368, magic_bishop_table.ptr + 2496,
  magic_bishop_table.ptr + 96, magic_bishop_table.ptr + 224,
  magic_bishop_table.ptr + 704, magic_bishop_table.ptr + 1088,
  magic_bishop_table.ptr + 1472, magic_bishop_table.ptr + 2112,
  magic_bishop_table.ptr + 2400, magic_bishop_table.ptr + 2528,
  magic_bishop_table.ptr + 2592, magic_bishop_table.ptr + 2688,
  magic_bishop_table.ptr + 832, magic_bishop_table.ptr + 1216,
  magic_bishop_table.ptr + 1600, magic_bishop_table.ptr + 2240,
  magic_bishop_table.ptr + 4864, magic_bishop_table.ptr + 4960,
  magic_bishop_table.ptr + 5056, magic_bishop_table.ptr + 2720,
  magic_bishop_table.ptr + 864, magic_bishop_table.ptr + 1248,
  magic_bishop_table.ptr + 1632, magic_bishop_table.ptr + 2272,
  magic_bishop_table.ptr + 4896, magic_bishop_table.ptr + 5184
];
const short magic_bishop_mobility_table[5248];
const short *magic_bishop_mobility_indices[64] = [
  magic_bishop_mobility_table.ptr + 4992, magic_bishop_mobility_table.ptr + 2624,
  magic_bishop_mobility_table.ptr + 256, magic_bishop_mobility_table.ptr + 896,
  magic_bishop_mobility_table.ptr + 1280, magic_bishop_mobility_table.ptr + 1664,
  magic_bishop_mobility_table.ptr + 4800, magic_bishop_mobility_table.ptr + 5120,
  magic_bishop_mobility_table.ptr + 2560, magic_bishop_mobility_table.ptr + 2656,
  magic_bishop_mobility_table.ptr + 288, magic_bishop_mobility_table.ptr + 928,
  magic_bishop_mobility_table.ptr + 1312, magic_bishop_mobility_table.ptr + 1696,
  magic_bishop_mobility_table.ptr + 4832, magic_bishop_mobility_table.ptr + 4928,
  magic_bishop_mobility_table.ptr + 0, magic_bishop_mobility_table.ptr + 128,
  magic_bishop_mobility_table.ptr + 320, magic_bishop_mobility_table.ptr + 960,
  magic_bishop_mobility_table.ptr + 1344, magic_bishop_mobility_table.ptr + 1728,
  magic_bishop_mobility_table.ptr + 2304, magic_bishop_mobility_table.ptr + 2432,
  magic_bishop_mobility_table.ptr + 32, magic_bishop_mobility_table.ptr + 160,
  magic_bishop_mobility_table.ptr + 448, magic_bishop_mobility_table.ptr + 2752,
  magic_bishop_mobility_table.ptr + 3776, magic_bishop_mobility_table.ptr + 1856,
  magic_bishop_mobility_table.ptr + 2336, magic_bishop_mobility_table.ptr + 2464,
  magic_bishop_mobility_table.ptr + 64, magic_bishop_mobility_table.ptr + 192,
  magic_bishop_mobility_table.ptr + 576, magic_bishop_mobility_table.ptr + 3264,
  magic_bishop_mobility_table.ptr + 4288, magic_bishop_mobility_table.ptr + 1984,
  magic_bishop_mobility_table.ptr + 2368, magic_bishop_mobility_table.ptr + 2496,
  magic_bishop_mobility_table.ptr + 96, magic_bishop_mobility_table.ptr + 224,
  magic_bishop_mobility_table.ptr + 704, magic_bishop_mobility_table.ptr + 1088,
  magic_bishop_mobility_table.ptr + 1472, magic_bishop_mobility_table.ptr + 2112,
  magic_bishop_mobility_table.ptr + 2400, magic_bishop_mobility_table.ptr + 2528,
  magic_bishop_mobility_table.ptr + 2592, magic_bishop_mobility_table.ptr + 2688,
  magic_bishop_mobility_table.ptr + 832, magic_bishop_mobility_table.ptr + 1216,
  magic_bishop_mobility_table.ptr + 1600, magic_bishop_mobility_table.ptr + 2240,
  magic_bishop_mobility_table.ptr + 4864, magic_bishop_mobility_table.ptr + 4960,
  magic_bishop_mobility_table.ptr + 5056, magic_bishop_mobility_table.ptr + 2720,
  magic_bishop_mobility_table.ptr + 864, magic_bishop_mobility_table.ptr + 1248,
  magic_bishop_mobility_table.ptr + 1632, magic_bishop_mobility_table.ptr + 2272,
  magic_bishop_mobility_table.ptr + 4896, magic_bishop_mobility_table.ptr + 5184
];
const ulong magic_rook_table[102400];
const ulong *magic_rook_indices[64] = [
  magic_rook_table.ptr + 86016, magic_rook_table.ptr + 73728,
  magic_rook_table.ptr + 36864, magic_rook_table.ptr + 43008,
  magic_rook_table.ptr + 47104, magic_rook_table.ptr + 51200,
  magic_rook_table.ptr + 77824, magic_rook_table.ptr + 94208,
  magic_rook_table.ptr + 69632, magic_rook_table.ptr + 32768,
  magic_rook_table.ptr + 38912, magic_rook_table.ptr + 10240,
  magic_rook_table.ptr + 14336, magic_rook_table.ptr + 53248,
  magic_rook_table.ptr + 57344, magic_rook_table.ptr + 81920,
  magic_rook_table.ptr + 24576, magic_rook_table.ptr + 33792,
  magic_rook_table.ptr + 6144, magic_rook_table.ptr + 11264,
  magic_rook_table.ptr + 15360, magic_rook_table.ptr + 18432,
  magic_rook_table.ptr + 58368, magic_rook_table.ptr + 61440,
  magic_rook_table.ptr + 26624, magic_rook_table.ptr + 4096,
  magic_rook_table.ptr + 7168, magic_rook_table.ptr + 0,
  magic_rook_table.ptr + 2048, magic_rook_table.ptr + 19456,
  magic_rook_table.ptr + 22528, magic_rook_table.ptr + 63488,
  magic_rook_table.ptr + 28672, magic_rook_table.ptr + 5120,
  magic_rook_table.ptr + 8192, magic_rook_table.ptr + 1024,
  magic_rook_table.ptr + 3072, magic_rook_table.ptr + 20480,
  magic_rook_table.ptr + 23552, magic_rook_table.ptr + 65536,
  magic_rook_table.ptr + 30720, magic_rook_table.ptr + 34816,
  magic_rook_table.ptr + 9216, magic_rook_table.ptr + 12288,
  magic_rook_table.ptr + 16384, magic_rook_table.ptr + 21504,
  magic_rook_table.ptr + 59392, magic_rook_table.ptr + 67584,
  magic_rook_table.ptr + 71680, magic_rook_table.ptr + 35840,
  magic_rook_table.ptr + 39936, magic_rook_table.ptr + 13312,
  magic_rook_table.ptr + 17408, magic_rook_table.ptr + 54272,
  magic_rook_table.ptr + 60416, magic_rook_table.ptr + 83968,
  magic_rook_table.ptr + 90112, magic_rook_table.ptr + 75776,
  magic_rook_table.ptr + 40960, magic_rook_table.ptr + 45056,
  magic_rook_table.ptr + 49152, magic_rook_table.ptr + 55296,
  magic_rook_table.ptr + 79872, magic_rook_table.ptr + 98304
];
const short magic_rook_mobility_table[102400];
const short *magic_rook_mobility_indices[64] = [
  magic_rook_mobility_table.ptr + 86016, magic_rook_mobility_table.ptr + 73728,
  magic_rook_mobility_table.ptr + 36864, magic_rook_mobility_table.ptr + 43008,
  magic_rook_mobility_table.ptr + 47104, magic_rook_mobility_table.ptr + 51200,
  magic_rook_mobility_table.ptr + 77824, magic_rook_mobility_table.ptr + 94208,
  magic_rook_mobility_table.ptr + 69632, magic_rook_mobility_table.ptr + 32768,
  magic_rook_mobility_table.ptr + 38912, magic_rook_mobility_table.ptr + 10240,
  magic_rook_mobility_table.ptr + 14336, magic_rook_mobility_table.ptr + 53248,
  magic_rook_mobility_table.ptr + 57344, magic_rook_mobility_table.ptr + 81920,
  magic_rook_mobility_table.ptr + 24576, magic_rook_mobility_table.ptr + 33792,
  magic_rook_mobility_table.ptr + 6144, magic_rook_mobility_table.ptr + 11264,
  magic_rook_mobility_table.ptr + 15360, magic_rook_mobility_table.ptr + 18432,
  magic_rook_mobility_table.ptr + 58368, magic_rook_mobility_table.ptr + 61440,
  magic_rook_mobility_table.ptr + 26624, magic_rook_mobility_table.ptr + 4096,
  magic_rook_mobility_table.ptr + 7168, magic_rook_mobility_table.ptr + 0,
  magic_rook_mobility_table.ptr + 2048, magic_rook_mobility_table.ptr + 19456,
  magic_rook_mobility_table.ptr + 22528, magic_rook_mobility_table.ptr + 63488,
  magic_rook_mobility_table.ptr + 28672, magic_rook_mobility_table.ptr + 5120,
  magic_rook_mobility_table.ptr + 8192, magic_rook_mobility_table.ptr + 1024,
  magic_rook_mobility_table.ptr + 3072, magic_rook_mobility_table.ptr + 20480,
  magic_rook_mobility_table.ptr + 23552, magic_rook_mobility_table.ptr + 65536,
  magic_rook_mobility_table.ptr + 30720, magic_rook_mobility_table.ptr + 34816,
  magic_rook_mobility_table.ptr + 9216, magic_rook_mobility_table.ptr + 12288,
  magic_rook_mobility_table.ptr + 16384, magic_rook_mobility_table.ptr + 21504,
  magic_rook_mobility_table.ptr + 59392, magic_rook_mobility_table.ptr + 67584,
  magic_rook_mobility_table.ptr + 71680, magic_rook_mobility_table.ptr + 35840,
  magic_rook_mobility_table.ptr + 39936, magic_rook_mobility_table.ptr + 13312,
  magic_rook_mobility_table.ptr + 17408, magic_rook_mobility_table.ptr + 54272,
  magic_rook_mobility_table.ptr + 60416, magic_rook_mobility_table.ptr + 83968,
  magic_rook_mobility_table.ptr + 90112, magic_rook_mobility_table.ptr + 75776,
  magic_rook_mobility_table.ptr + 40960, magic_rook_mobility_table.ptr + 45056,
  magic_rook_mobility_table.ptr + 49152, magic_rook_mobility_table.ptr + 55296,
  magic_rook_mobility_table.ptr + 79872, magic_rook_mobility_table.ptr + 98304
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