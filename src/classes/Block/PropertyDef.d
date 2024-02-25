/**
 * Egy property definíciója az osztályon belül
 */
import std.stdio;
import std.string;
import std.regex;
import Block:Block;
import Namespace:Namespace;
import ClassData:ClassData;
import ObjectData:ObjectData;
import AsmWriter:AsmWriter;
import ClassProperty:ClassProperty;

class PropertyDef : Block {

    public static PropertyDef it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^(DB|DW)\s+([^\s]+)$" ) ) {
            string type = m[1];
            string property_name = m[2];
            return new PropertyDef( ns, depth, line, owner_class_name, type, property_name );
        } else {
            return null;
        }
    }

    private string type; // "DB" vagy "DW"
    private string property_name;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string type, string property_name ) {
        super( ns, depth, origi_line, owner_class_name );
        this.type = type;
        this.property_name = property_name;

        ClassData owner_class_data = ns.get_class_data( owner_class_name );
        owner_class_data.add_property( property_name, type );
    }

    override public void convert_content( AsmWriter writer ) {
        // string property_label = format( "Class_%s_Property_%s_Type_%s_Data", this.owner_class_name, this.property_name, this.type );
        ClassData owner_class_data = this.ns.get_class_data( this.owner_class_name );
        ClassProperty prop = owner_class_data.get_property_data( this.property_name );
        if ( prop is null ) throw new Exception( format( "Property '%s' not found!", this.property_name ) );
        if ( owner_class_data.multi_instance() ) { // label = shift label
            writer.add_code_label( prop.get_property_def_label(), format( "EQU %d ; %s", prop.get_property_shift0(), this.origi_line ), this.depth );
        } else {
            writer.add_code_label( prop.get_property_def_label(), format( "%s 0 ; %s", this.type, this.origi_line ), this.depth );
        }
    }

}
