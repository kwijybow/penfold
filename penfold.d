import std.stdio, std.string, std.array, std.conv, std.datetime;
import position;
import hash;

void main (char[][] args) {
    Position p;
    bool ok = true;
    ulong fen_count = 0;
    ulong error_count = 0;
    char[] fen_out;
    
    p = new Position();
    p.startPosition();
    p.printPosition();
    writeln;
    
    InitializeHashTables();
    
    foreach (line; File("test.fen").byLine()) {
        line = chomp(line);
        //writefln("%s",line);
        ok = p.setFEN(line);
        if (ok) {
            fen_count++;
            p.printPosition();
            ok = p.getFEN(fen_out);
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
}
    
    