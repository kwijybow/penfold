import std.stdio, std.string, std.array, std.conv;
import core.bitop;
import chess;
import masks;
import bitboard;


ulong knight_attacks[64];

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

void InitializeAttacks() {

    for (int i=0; i<64; i++) {
        knight_attacks[i] = genKightAttack(i);
    }
}