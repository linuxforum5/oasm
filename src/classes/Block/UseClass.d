/**
 * Értékadás
 */
import std.stdio;
import std.string;
import std.regex;
import Block:Block;
import Namespace:Namespace;
import AsmWriter:AsmWriter;
import ClassData:ClassData;

class UseClass : Block {

    public static UseClass it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^use\s+class\s([^\s]+)$" ) ) {
            string class_name = m[1];
            return new UseClass( ns, depth, line, owner_class_name, class_name );
        } else {
            return null;
        }
    }

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string class_name ) {
        super( ns, depth, origi_line, owner_class_name );
        ClassData class_data = this.ns.get_class_data( class_name );
    }

    override public void convert_content( AsmWriter writer ) {
    }

}
