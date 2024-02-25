/**
 * Ciklusból való kiugrás
 */
import std.stdio;
import std.string;
import std.regex;
import std.algorithm;
import Block:Block;
import Namespace:Namespace;
import ClassData:ClassData;
import ClassMethod:ClassMethod;
import ClassProperty:ClassProperty;
import ObjectData:ObjectData;
import AsmWriter:AsmWriter;
import VariableData:VariableData;
import Let:Let;
import Register8bit:Register8bit;
import Register16bit:Register16bit;

class Break : Block {

    public static Break it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^break$" ) ) {
            return new Break( ns, depth, line, owner_class_name );
        } else {
            return null;
        }
    }

    private string label;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name ) {
        super( ns, depth, origi_line, owner_class_name );
        this.label = ns.get_break_label();
    }

    override public void convert_content( AsmWriter writer ) {
        writer.add_code( format( "JR %s ; %s", this.label, this.origi_line ), this.depth );
    }

}
