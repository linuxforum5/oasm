/**
 * Egy olyan forrás kódsor, ami egy objektum/osztly egy műveletét hívja meg.
 * 
 */
import std.stdio;
import std.string;
import std.regex;
import std.algorithm;
import Block:Block;
import Namespace:Namespace;
import ClassData:ClassData;
import Condition:Condition;
import ClassMethod:ClassMethod;
import ObjectData:ObjectData;
import AsmWriter:AsmWriter;
import VariableData:VariableData;
import Let:Let;
import Register8bit:Register8bit;
import Register16bit:Register16bit;
import ClassProperty:ClassProperty;
import PropertyDirect:PropertyDirect;

class Call : Block {

    public static Call it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^([^\s]+)\.([^\s]+)\((.*)\)\s*if\s*\((.*)\)$" ) ) {            // Feltételes művelethívás
            string class_or_object_name = m[1];
            string method = m[2];
            string param_str = m[3];
            string if_str = strip( m[4] );
            return new Call( ns, depth, line, owner_class_name, class_or_object_name, method, param_str, if_str ); // Feltételnélküli művelethívás
        } else if ( auto m = std.regex.matchFirst( line, r"^([^\s]+)\.([^\s]+)\((.*)\)$" ) ) {
            string class_or_object_name = m[1];
            string method = m[2];
            string param_str = m[3];
            return new Call( ns, depth, line, owner_class_name, class_or_object_name, method, param_str, "" );
        } else {
            return null;
        }
    }

    private string class_or_object_name;
    private string method_name;
    private string param_str;
    private string if_str; // Feltételes ugrás esetén ez a feltétel
    private bool this_or_parent; // Igaz, ha a "this" vagy a "parent" az objektumazonosító

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string class_or_object_name, string method_name, string param_str, string if_str ) {
        super( ns, depth, origi_line, owner_class_name );
        this.method_name = method_name;
        this.param_str = param_str;
        this.class_or_object_name = class_or_object_name;
        this.this_or_parent = ( class_or_object_name == "this" ) || ( class_or_object_name == "parent" );
        if ( auto m = std.regex.matchFirst( if_str, r"^\s*(Z|NZ|CY|NCY|P|M|)\s*$" ) ) {
            this.if_str = if_str;
        } else {
            throw new Exception( "Feltételes hívásnál csak Flag-ek adhatók meg a feltételben." );
        }
    }

    protected string abs_class_name( string class_or_object_name ) {
        if ( class_or_object_name == "this" ) {
            if ( this.owner_class_name.length > 0 ) {
                ClassData user_class_data = this.ns.get_class_data( this.owner_class_name );
                class_or_object_name = user_class_data.get_method_definitor_class_name( this.method_name );
            } else {
                throw new Exception( format( "Unable to use 'this' without Class! : %s", this.origi_line ) );
            }
        } else if ( class_or_object_name == "parent" ) {
            if ( this.owner_class_name.length > 0 ) {
                ClassData user_class_data = this.ns.get_class_data( this.owner_class_name );
                ClassData parent_class_data = user_class_data.get_parent_class_data();
                class_or_object_name = parent_class_data.get_method_definitor_class_name( this.method_name );
            } else {
                throw new Exception( format( "Unable to use 'this' without Class! : %s", this.origi_line ) );
            }
        }
        return class_or_object_name;
    }

    override public void convert_content( AsmWriter writer ) {
        this.class_or_object_name = this.abs_class_name( this.class_or_object_name ); // Ez lecseréli a this és parent kulcsszavakat a valódi osztálynévre. Ezt nyugodtan megteheti. (Itt már nem kell Index check???)
        if ( this.ns.is_class( this.class_or_object_name ) ) { // Ez egy osztály neve, statikus művelet hívás
            ClassData class_data = this.ns.get_class_data( this.class_or_object_name );
//            this.ns.register_call( class_data.get_method_label( this.method_name ) );

            class_data.gen_class_method_call_code( writer, this.owner_class_name, this.method_name, this.param_str, this.if_str, this.origi_line, this.depth );

        } else if ( this.ns.is_object( this.class_or_object_name ) ) { // Egy objektum neve. Objektumművelet hívása
            ObjectData object_data = this.ns.get_object_data( this.class_or_object_name );
//            this.ns.register_call( object_data.get_class_data().get_method_label( this.method_name ) );

            object_data.gen_object_method_call_code( writer, this.owner_class_name, this.method_name, this.param_str, this.if_str, this.origi_line, this.depth );

        } else if ( auto m = std.regex.matchFirst( this.class_or_object_name, r"^(this|[^\s\.]+).([^\s\.]+)$" ) ) { // Egy objektum-property művelete
//        } else if ( auto m = std.regex.matchFirst( this.class_or_object_name, r"^(this|GAME\.points).([^\s\.]+)$" ) ) { // Egy objektum-property művelete
//        } else if ( auto m = std.regex.matchFirst( this.class_or_object_name, r"^(this).([^\s\.]+)$" ) ) { // Egy objektum-property művelete
            string object_or_classname = m[ 1 ];
            string property_name = m[ 2 ];
            ClassData user_class_data = ( object_or_classname == "this" ) ? this.ns.get_class_data( this.owner_class_name )
                                                                          : this.ns.get_object_data( object_or_classname ).get_class_data();
            ClassProperty prop = user_class_data.get_property_data( property_name );
            PropertyDirect dProp = cast(PropertyDirect)prop;
            if ( prop ) {
                ObjectData pointed_object = dProp.get_pointed_object();
//                this.ns.register_call( pointed_object.get_class_data().get_method_label( this.method_name ) );
                string owner_class_name = pointed_object.get_class_data().get_method_definitor_class_name( this.method_name );

                pointed_object.gen_object_method_call_code( writer, owner_class_name, this.method_name, this.param_str, this.if_str, this.origi_line, this.depth );
            } else {
                throw new Exception( format( "Object or class not found: '%s' in line '%s'", this.class_or_object_name, this.origi_line ) );
            }
        } else { // Load class @TODO: Ez jó, hogy ha nem találja meg az objektumot, akkor megpróbálja betölteni, mint osztályt? Ne maradjon inkább a "use class ..."?
//            ClassData class_data = this.ns.get_class_data( this.class_or_object_name );
//            class_data.gen_method_call_code( writer, this.owner_class_name, this.method_name, this.param_str, this.if_str, this.origi_line, this.depth );
            throw new Exception( format( "Object or class not found: '%s' in line '%s'", this.class_or_object_name, this.origi_line ) );
        }
    }

    public static void write_content( Namespace ns, string owner_class_name, AsmWriter writer, ClassData class_data, string method_name, string call_param_str, string call_if_str, string comment, uint depth ) {
        if ( class_data.is_method( method_name ) ) {
            string label = class_data.get_method_label( method_name );
            ClassMethod method_data = class_data.get_method_data( method_name );
            string def_param_str = method_data.get_param_str();
            string[] def_params = Call.split_param( strip( def_param_str ) );
            string[] call_params = Call.split_param( strip( call_param_str ) );
            if ( def_params.length == call_params.length ) {
                for( int i=0; i<def_params.length; i++ ) {
                    if ( def_params[ i ] != call_params[ i ] ) { // Csak eltérés eserén kell kódot generálni
                        Call.write_param_let( ns, owner_class_name, writer, strip( def_params[ i ] ), strip( call_params[ i ] ), comment, depth );
                    }
                }
            } else {
                throw new Exception( format( "Paraméterszám nem megfelelő. Definíció: '%s', Hivás: .%s(%s) in class '%s'", def_param_str, method_name, call_param_str, owner_class_name ) );
            }
            string ASM_CALL_CMD = "CALL";
//            if ( ns.get_call_counter( label ) == 1 ) {
//                ASM_CALL_CMD = "JP";
//            }
            if ( call_if_str.length > 0 ) {
                writer.add_code( format( "%s %s, %s ; %s", ASM_CALL_CMD, Condition.oasmFlagToAsmFlag( call_if_str ), label, comment ), depth );
            } else {
                writer.add_code( format( "%s %s ; %s", ASM_CALL_CMD, label, comment ), depth );
            }
//            string call_label = ns.get_last_call_label( label );
//            writer.add_code_label( call_label );
        } else if ( method_name == "constructor" ) { // A konstruktor speciális művelet, nem feltétlen kell definiálva lennie!
        } else {
            throw new Exception( format( "Method '%s' not defined in class '%s'", method_name, class_data.get_class_name() ) );
        }
    }

    private static string[] split_param( string param_str ) {
        string[] slices = param_str.split( ',' );
        string[] valid_slices = [];
        if ( slices.length > 0 ) {
            valid_slices ~= slices[ 0 ];
            for( int i=1; i<slices.length; i++ ) {
                if ( Call.valid_slice( valid_slices[ valid_slices.length - 1 ] ) ) {
                    valid_slices ~= slices[ i ];
                } else {
                    valid_slices[ valid_slices.length - 1 ] ~= "," ~ slices[ i ];
                }
            }
            for( int i = 1; i < valid_slices.length; i++ ) {
                valid_slices[ i ] = strip( valid_slices[ i ] );
            }
        }
        return valid_slices;
    }

    private static bool valid_slice( string slice ) {
        if ( count( slice, '"' ) % 2 != 0 ) return false;
        if ( count( slice, '(' ) != count( slice, ')' ) ) return false;
        return true;
    }

    private static void write_param_let( Namespace ns, string owner_class_name, AsmWriter writer, string dest_param, string source_param_str, string comment_origi_line, uint depth ) {
        VariableData value_data = Let.get_variable_data_from_value_string( ns, owner_class_name, source_param_str );
        if ( Register8bit reg = Register8bit.it_is_this( ns, owner_class_name, dest_param ) ) {
            reg.load_value_from( writer, value_data, comment_origi_line, depth );
        } else if ( Register16bit reg = Register16bit.it_is_this( ns, owner_class_name, dest_param ) ) {
            reg.load_value_from( writer, value_data, comment_origi_line, depth );
        } else {
            throw new Exception( "Paraméterdefinícióban csak regiszeterk használata engedélyezett!" );
        }
    }

}
