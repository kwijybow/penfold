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
    int move_index = 0;
    int num_moves = 0;
    

    InitializeSquares();
    InitializeMasks();
    InitializeAttacks();
    InitializeMagic();
    InitializeHashTables();    
    
    
    t = new Tree;
    t.p.startPosition();
    t.p.printPosition();
    writeln;
    
    t.move_list[1].length = 5120;
    t.move_list[1][] = 0;
    num_moves = GenerateCaptures(t, 1, t.p.ctm, move_index);
    for (int i=0; i< 10; i++)
        writef("%s ",t.move_list[1][i]);
    writeln;
    
    foreach (line; File("/home/nelson/data/chess/data/test.fen").byLine()) {
        line = chomp(line);
        //writefln("%s",line);
        ok = t.p.setFEN(line);
        t.move_list[1][] = 0;
        move_index = 0;
        num_moves = 0;
        num_moves = GenerateCaptures(t, 1, t.p.ctm, move_index);
//        writefln("num_moves %s, move_index %s",num_moves, move_index);
//        for (int i=0; i< 10; i++)
//            writef("%s ",t.move_list[1][i]);
//        writeln;        
        if (ok) {
            fen_count++;
            if ((fen_count % 100000) == 0) {writefln("fen_count = %s",fen_count);}
            if (HashProbe(t, 1, 1, t.p.ctm, 0, 0, val) > 0) {
                //writefln("hash key %s",p.hash_key);
                collisions++;
                value = val + 1;
                if (value > max) {
                    max = value;
//                    writefln("new max = %s",max);
//                    writefln("total collisions = %s",collisions);
                    //writefln("hash key %s",p.hash_key);
//                    writefln("%s",line);
//                    t.p.printPosition();
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
    
    