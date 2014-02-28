import std.stdio, std.string, std.array, std.conv;
import core.bitop;
import chess;
import masks;
import bitboard;


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