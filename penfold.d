import std.stdio, std.string, std.array, std.conv, std.datetime;
import position;

void main (char[][] args) {
    Position p;
    bool ok = true;
    
    p = new Position();
    p.startPosition();
    p.printPosition();
    ok = p.setFEN("rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2".dup);
    writeln;
    if (ok) {p.printPosition();}
    
}
    
    