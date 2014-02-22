import std.stdio, std.string, std.array;
import core.bitop;

class Position {
    enum Color { white = 0, black = 0 };
    enum Piece { pawn = 1, knight = 2, bishop = 3, rook = 4, queen = 5, king = 6 };
    
    Color ctm;
    ulong whitepawns;
    ulong whiterooks;
    ulong whiteknights;
    ulong whitebishops;
    ulong whitequeen;
    ulong whiteking;
    ulong blackpawns;
    ulong blackrooks;
    ulong blackknights;
    ulong blackbishops;
    ulong blackqueen;
    ulong blackking;
    ulong occupied;
    ulong empty;
    
    
    
    this() {
        whitepawns   = 0;
        whiterooks   = 0;
        whiteknights = 0;
        whitebishops = 0;
        whitequeen   = 0;
        whiteking    = 0;
        blackpawns   = 0;
        blackrooks   = 0;
        blackknights = 0;
        blackbishops = 0;
        blackqueen   = 0;
        blackking    = 0;
        occupied     = 0;
        empty        = ~occupied;
    }
    
    void dropPiece (Color color, Piece piece, string square) {
    }
    
    void startPosition() {
        string whitesquare;
        string blacksquare;
    
        foreach(col; ["a","b","c","d","e","f","g","h"]) {
            whitesquare = col ~ "2";
            blacksquare = col ~ "7";
            dropPiece(Color.white, Piece.pawn, whitesquare);
            dropPiece(Color.black, Piece.pawn, blacksquare);
        }
        
        dropPiece(Color.white, Piece.rook,   "a1");
        dropPiece(Color.white, Piece.rook,   "h1");
        dropPiece(Color.white, Piece.knight, "b1");
        dropPiece(Color.white, Piece.knight, "g1");
        dropPiece(Color.white, Piece.bishop, "c1");
        dropPiece(Color.white, Piece.bishop, "f1");
        dropPiece(Color.white, Piece.queen,  "d1");
        dropPiece(Color.white, Piece.king,   "e1");
 
        dropPiece(Color.black, Piece.rook,   "a8");
        dropPiece(Color.black, Piece.rook,   "h8");
        dropPiece(Color.black, Piece.knight, "b8");
        dropPiece(Color.black, Piece.knight, "g8");
        dropPiece(Color.black, Piece.bishop, "c8");
        dropPiece(Color.black, Piece.bishop, "f8");
        dropPiece(Color.black, Piece.queen,  "d8");
        dropPiece(Color.black, Piece.king,   "e8");
 
    }    
    
}