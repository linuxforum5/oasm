/**
 * Hívás
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

class IncDec : Block {

    public static IncDec it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^(INC|DEC|inc|dec)\s+([^\s]+)\.([^\s]+)$" ) ) {
            string command = m[1];
            string class_or_object_name = m[2];
            string property_name = m[3];
            return new IncDec( ns, depth, line, owner_class_name, class_or_object_name, property_name, command );
        } else {
            return null;
        }
    }

    private string class_or_object_name;
    private string property_name;
    private string command;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string class_or_object_name, string property_name, string command ) {
        super( ns, depth, origi_line, owner_class_name );
        if ( class_or_object_name == "this" ) class_or_object_name = owner_class_name;
        if ( class_or_object_name == "parent" ) class_or_object_name = owner_class_name;
        this.class_or_object_name = class_or_object_name;
        this.property_name = property_name;
        this.command = command;
    }

    override public void convert_content( AsmWriter writer ) {
        ClassData class_data = null;
        // this.class_or_object_name = this.abs_class_name( this.class_or_object_name ); // Ez lecseréli a this és parent kulcsszavakat a valódi osztálynévre. Ezt nyugodtan megteheti. (Itt már nem kell Index check???)
        if ( this.ns.is_class( this.class_or_object_name ) ) { // Ez egy osztály neve, statikus property
            class_data = this.ns.get_class_data( this.class_or_object_name );
        } else if ( this.ns.is_object( this.class_or_object_name ) ) {
            ObjectData object_data = this.ns.get_object_data( this.class_or_object_name );
            class_data = object_data.get_class_data();
        } else { // Load class @TODO: Ez jó, hogy ha nem találja meg az objektumot, akkor megpróbálja betölteni, mint osztályt? Ne maradjon inkább a "use class ..."?
            throw new Exception( format( "Object or class not found: '%s' in line '%s'", this.class_or_object_name, this.origi_line ) );
        }
        ClassProperty prop = class_data.get_property_data( this.property_name );
        uint byte_address = 0;
        prop.inc_dec( writer, this.command, byte_address, this.origi_line, this.depth );
    }

}
