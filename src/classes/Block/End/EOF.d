/**
 * Egyszerű blokkvége. Egyedi if, class, method
 */
import std.stdio;
import std.string;
import std.regex;
import Block:Block;
import Namespace:Namespace;
import AsmWriter:AsmWriter;

class EOF : Block {

    private string filename;

    this( Namespace ns, uint depth, string filename ) {
        super( ns, depth, "<EOF>", "" );
        this.filename = filename;
    }


    override public void convert_content( AsmWriter writer ) {
        writer.add_data( "EOF", format( "; <EOF> : '%s'", this.filename ), 0 );
    }

}
