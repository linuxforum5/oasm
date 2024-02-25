/**
 * Értékadás egy oldalának adattípusa
 */
import std.stdio;
import std.string;
import std.regex;
import Namespace:Namespace;
import VariableData:VariableData;
import AsmWriter:AsmWriter;
import ObjectData:ObjectData;
import ClassData:ClassData;
import ClassProperty:ClassProperty;

class Property : VariableData {

    public static Property it_is_this( Namespace ns, string owner_class_name, string side ) {
        if ( auto m = std.regex.matchFirst( side, r"^([^\s]+)\.([^\s\+]+)(|\+1)$" ) ) {
            string object_name = m[1];
            string property_name = m[2];
            string byte_address_str = m[3]; // +1 a DW második, HIGH bájtja
            return new Property( ns, owner_class_name, object_name, property_name, byte_address_str );
        } else {
            return null;
        }
    }

    private string class_or_object_name;
    private string property_name;
    private uint byte_address; // 0 vagy 1 DW esetén: 0=az alacsony helyiértékű bájt címe, azaz az egész property címe, 1 esetén a magasabb helyiérték, azaz a második bájt címe. Értékadásnál fontos csak
    private string property_label; // PropertiesDirect esetén ez közvetlen memóriacím, PropertiesIX/IY esetén a +d shift értékét azonosító label
    private string index_base_register; // IX, IY vagy üres, direkt memóriacímzés esetén

    this( Namespace ns, string owner_class_name, string class_or_object_name, string property_name, string byte_address_str ) {
        super( ns, owner_class_name );
        if ( owner_class_name.length == 0 ) throw new Exception( format( "Property without owner class_name or object '%s.%s' (%s %d. sor)", class_or_object_name, property_name, this.ns.get_filename(), this.ns.get_line_number() ) );
        if ( class_or_object_name == "this" ) class_or_object_name = owner_class_name;
        if ( class_or_object_name == "parent" ) class_or_object_name = owner_class_name;
        this.class_or_object_name = class_or_object_name;
        this.property_name = property_name;
        this.byte_address = ( byte_address_str == "+1" ) ? 1 : 0;
        // if ( this.owner_class_name.length == 0 ) throw new Exception( format( "Property without owner class or object '%s' 1", this.class_or_object_name ) );

//        if ( !ns.is_object( class_or_object_name ) ) {
//            ns.add_object( class_or_object_name, new ObjectData( class_or_object_name, null ) ); // Amíg nem ismerjük az objektum osztályát, addig null
//        }

        // if ( this.owner_class_name.length == 0 ) throw new Exception( format( "Property without owner class or object '%s' 2", this.class_or_object_name ) );
    }

    public uint get_byte_address() { return this.byte_address; }

    protected string abs_class_name( string class_or_object_name ) {
        if ( ( class_or_object_name == "this" ) || ( class_or_object_name == "parent" ) ) {
            if ( this.owner_class_name.length > 0 ) {
                ClassData user_class_data = this.ns.get_class_data( this.owner_class_name );
                class_or_object_name = user_class_data.get_property_definitor_class_name( this.property_name );
            } else {
                throw new Exception( format( "Unable to use 'this' without Class! (1)" ) );
            }
        }
        return class_or_object_name;
    }

    override public void load_value_from( AsmWriter writer, VariableData right_var_data, string comment, uint depth ) {
        ClassProperty property_data = this.get_property_data( writer, comment );
/*
        string class_or_object_name = this.abs_class_name( this.class_or_object_name );


        if ( this.ns.is_object( class_or_object_name ) ) { // Van ilyen néven objektum
            ObjectData object_data = this.ns.get_object_data( this.class_or_object_name ); // Ennek egy memberváltozóját állítjuk
            property_data = object_data.get_property_data( writer, this.property_name );
        } else if ( this.ns.is_class( class_or_object_name ) ) { // Van ilyen osztály
            ClassData class_data = this.ns.get_class_data( this.class_or_object_name ); // Ennek egy memberváltozóját állítjuk
            property_data = class_data.get_property_data( this.property_name );
        } else {
            throw new Exception( format( "Object or class '%s' not found for property owner! (%s)", class_or_object_name, comment ) );
        }
*/
        if ( property_data is null ) throw new Exception( format( "Property '%s' of object or class '%s' not found!", this.property_name, class_or_object_name ) );
        property_data.load_value_from( writer, right_var_data, this.byte_address, comment, depth );
    }

    public ClassProperty get_property_data( AsmWriter writer, string comment ) {
        string class_or_object_name = this.abs_class_name( this.class_or_object_name );
        if ( this.ns.is_object( class_or_object_name ) ) { // Van ilyen néven objektum
            ObjectData object_data = this.ns.get_object_data( class_or_object_name ); // Ennek egy memberváltozóját állítjuk
            return object_data.get_property_data( writer, this.property_name );
        } else if ( this.ns.is_class( class_or_object_name ) ) { // Van ilyen osztály
            ClassData class_data = this.ns.get_class_data( this.class_or_object_name ); // Ennek egy memberváltozóját állítjuk
            return class_data.get_property_data( this.property_name );
/*
        } else if ( auto m = std.regex.matchFirst( this.class_or_object_name, r"^(this|[^\s\.]+).([^\s\.]+)$" ) ) { // Egy objektum-property művelete
            string object_or_classname = m[ 1 ];
            string property_name = m[ 2 ];
            ClassData user_class_data = ( object_or_classname == "this" ) ? this.ns.get_class_data( this.owner_class_name )
                                                                          : this.ns.get_object_data( object_or_classname ).get_class_data();
            ClassProperty prop = user_class_data.get_property_data( property_name );
            return prop;
            PropertyDirect dProp = cast(PropertyDirect)prop;
            if ( prop ) {
                ObjectData pointed_object = dProp.get_pointed_object();
//                this.ns.register_call( pointed_object.get_class_data().get_method_label( this.method_name ) );
                string owner_class_name = pointed_object.get_class_data().get_method_definitor_class_name( this.method_name );

                pointed_object.gen_object_method_call_code( writer, owner_class_name, this.method_name, this.param_str, this.if_str, this.origi_line, this.depth );
            } else {
                throw new Exception( format( "Object or class not found: '%s' in line '%s'", this.class_or_object_name, this.origi_line ) );
            }
*/
        } else {
            throw new Exception( format( "Object or class '%s' not found for property owner! (%s)", class_or_object_name, comment ) );
        }
    }

}
