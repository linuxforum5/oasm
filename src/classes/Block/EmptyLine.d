/**
 * Üres sor
 */
import std.stdio;
import std.regex;
import Block:Block;
import Namespace:Namespace;

class EmptyLine : Block {

    public static EmptyLine it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^\s*$" ) ) {
            return new EmptyLine( ns, depth, line, owner_class_name );
        } else {
            return null;
        }
    }

    this( Namespace ns, uint depth, string origi_line, string owner_class_name ) {
        super( ns, depth, origi_line, owner_class_name );
    }

}
