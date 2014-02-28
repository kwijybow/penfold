import std.stdio, std.string, std.array, std.conv, std.datetime;
import position;
import hash;
import chess;
import tree;
import masks;
import attacks;
import move;

void main (char[][] args) {
    Position p;
    Tree t;
    bool ok = true;
    ulong fen_count = 0;
    ulong error_count = 0;
    char[] fen_out;
    int value = 0;
    int val = 0;
    int max = 0;
    int collisions = 0;
    int mvp;
    int test;

    InitializeSquares();
    InitializeMasks();
    InitializeAttacks();
    InitializeHashTables();    
    
    
    t = new Tree;
    t.p.startPosition();
    t.p.printPosition();
    writeln;
    
    mvp = GenerateCaptures(t, 1, t.p.ctm, test);
    
    foreach (line; File("/home/nelson/data/chess/data/test.fen").byLine()) {
        line = chomp(line);
        //writefln("%s",line);
        ok = t.p.setFEN(line);
        if (ok) {
            fen_count++;
            if (HashProbe(t, 1, 1, t.p.ctm, 0, 0, val) > 0) {
                //writefln("hash key %s",p.hash_key);
                collisions++;
                value = val + 1;
                if (value > max) {
                    max = value;
                    writefln("new max = %s",max);
                    writefln("total collisions = %s",collisions);
                    //writefln("hash key %s",p.hash_key);
                    writefln("%s",line);
                    t.p.printPosition();
                }
                //writefln("value = %s",value);
            }
            //value++;
            HashStore(t, 1, 1, t.p.ctm, EXACT, value, 0);
            value = 0;
            //p.printPosition();
            ok = t.p.getFEN(fen_out);
            if (!(fen_out == line)) {
                error_count++;
                writeln("error writing FEN!");
                writefln("In : %s",line);
                writefln("Out: %s",fen_out);
                
            }
        }    
        else {
            writeln("error reading FEN!");
            writeln(line);
            error_count++;
        }
    }
    writefln("%s positions read, %s errors encountered.", fen_count, error_count);
    writefln("total hash table collisions %s",collisions);
    
}
    
    