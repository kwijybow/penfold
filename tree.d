import std.stdio, std.string, std.array, std.conv;
import core.bitop;
import hash;
import chess;
import position;



class Tree {
    Position p;
    Path pv[MAXPLY];
    int hash_move[MAXPLY];
    int curmv[MAXPLY];
    int[] move_list[MAXPLY];
    
    this() {
        p = new Position();
    }
}

void SavePV(ref Tree tree, int ply, int ph) {

    tree.pv[ply-1].path[ply-1] = tree.curmv[ply-1];                     
    tree.pv[ply-1].pathl=to!ubyte(ply);                                          
    tree.pv[ply-1].pathh=to!ubyte(ph);                                           
    tree.pv[ply-1].pathd=to!ubyte(iteration_depth);
}