import std.stdio, std.string, std.array, std.conv;
import core.bitop;
import bitboard;
import chess;



ulong filemask[8] = [0,0,0,0,0,0,0,0];
ulong rankmask[8] = [0,0,0,0,0,0,0,0];
ulong[string] filemask_by_name;
ulong[string] rankmask_by_name;
ulong[string] avoidwrap_by_name;
ulong clear_mask[65];
ulong set_mask[65];

void InitializeMasks() {

    for (int i=0; i<64; i++) {
        filemask[(i&7)] |= to!ulong(1) << i;
        rankmask[(i>>3)] |= to!ulong(1) << i;
        clear_mask[i] = ~(to!ulong(1) << i);
        set_mask[i] = to!ulong(1) << i;
    }
    filemask_by_name["a"] = filemask[7];
    filemask_by_name["b"] = filemask[6];
    filemask_by_name["c"] = filemask[5];
    filemask_by_name["d"] = filemask[4];
    filemask_by_name["e"] = filemask[3];
    filemask_by_name["f"] = filemask[2];
    filemask_by_name["g"] = filemask[1];
    filemask_by_name["h"] = filemask[0];
    
    rankmask_by_name["1"] = rankmask[0];
    rankmask_by_name["2"] = rankmask[1];
    rankmask_by_name["3"] = rankmask[2];
    rankmask_by_name["4"] = rankmask[3];
    rankmask_by_name["5"] = rankmask[4];
    rankmask_by_name["6"] = rankmask[5];
    rankmask_by_name["7"] = rankmask[6];
    rankmask_by_name["8"] = rankmask[7];
    
    clear_mask[BAD_SQUARE] = 0;
    set_mask[BAD_SQUARE] = 0;
}