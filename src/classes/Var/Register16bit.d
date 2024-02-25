/**
 * Értékadás egy oldalának adattípusa
 */
import std.stdio;
import std.string;
import std.regex;
import Namespace:Namespace;
import VariableData:VariableData;
import AsmWriter:AsmWriter;
import Register8bit:Register8bit;
import Property:Property;
import StringConstant:StringConstant;
import UnconvertedAsmCode:UnconvertedAsmCode;
import ClassProperty:ClassProperty;
import CallClassConstructor:CallClassConstructor;
import ClassData:ClassData;
import ObjectData:ObjectData;
import Call:Call;
import DefineObject:DefineObject;

class Register16bit : VariableData {

    public static Register16bit it_is_this( Namespace ns, string owner_class_name, string side ) {
        if ( auto m = std.regex.matchFirst( side, r"^(AF|BC|DE|HL|IX|IY)$" ) ) {
            string register_name = m[1];
            return new Register16bit( ns, owner_class_name, register_name );
        } else {
            return null;
        }
    }

    private string register_name;
    private static uint counter = 0;

    this( Namespace ns, string owner_class_name, string register_name ) {
        super( ns, owner_class_name );
        this.register_name = register_name;
    }

    public string get_register_name() { return this.register_name; }
    public char get_register_name_first_character() { return this.register_name[0]; }
    public char get_register_name_last_character() { return this.register_name[1]; }

    override public void load_value_from( AsmWriter writer, VariableData right_var_data, string comment, uint depth ) {
        if ( Property v = cast(Property)right_var_data ) {
            ClassProperty prop = v.get_property_data( writer, comment );
            prop.load_value_into( writer, this, v.get_byte_address(), comment, depth );
        } else if ( Register16bit v = cast(Register16bit)right_var_data ) {
            if ( v.get_register_name() != this.get_register_name() ) {
                writer.add_code( format( "LD %c, %c ; %s", this.get_register_name_first_character(), v.get_register_name_first_character(), comment ), depth );
                writer.add_code( format( "LD %c, %c ; %s", this.get_register_name_last_character(), v.get_register_name_last_character(), comment ), depth );
            }
        } else if ( Register8bit v = cast(Register8bit)right_var_data ) {
            throw new Exception( format( "16 bites registerbe nem tölthető 8 bites regiszter: %s", comment ) );
        } else if ( StringConstant v = cast(StringConstant)right_var_data ) {
            writer.add_code( format( "LD %s, %s ; %s", this.get_register_name(), v.get_string_data_label(), comment ), depth );
            writer.add_data( v.get_string_data_label(), format( "DB \"%s\",0 ; %s", v.get_string_content(), comment ), 1 );
        } else if ( UnconvertedAsmCode v = cast(UnconvertedAsmCode)right_var_data ) {
            writer.add_code( format( "LD %s, %s ; direct asm value ; %s", this.register_name, v.get_asm_code(), comment ), depth );
        } else if ( CallClassConstructor constructor = cast(CallClassConstructor)right_var_data ) {
            ObjectData obj_data = DefineObject.generate_new_indexed_object_code( writer, this.ns, "", constructor, this.owner_class_name, comment, depth );
            string obj_data_label = obj_data.get_data_label();
            writer.add_code( format( "LD %s, %s ; %s", this.register_name, obj_data_label, comment ), depth );
/*
            ClassData class_data = constructor.get_class_data();
            if ( class_data.multi_instance() ) { // Ennek az osztálynak lehet több objektuma is, így memóriát kell allokálni az egyes példányok számára
                string obj_data_label = this.get_temp_obj_data_label( class_data.get_class_name() );
                class_data.gen_object_selector_code( writer, obj_data_label, comment, depth );
                writer.add_data( obj_data_label, format( "DS %d,0 ; %s", class_data.get_class_data_size(), comment ) ); // Allocate memory in data segment: DS size,0
                Call.write_content( this.ns, this.owner_class_name, writer, class_data, "constructor", constructor.get_constructor_param_str(), "", comment, depth );
                writer.add_code( format( "LD %s, %s ; %s", this.register_name, obj_data_label, comment ), depth );
            } else {
                throw new Exception( "Paraméter objektum csak idnexelt osztályból származhat!" );
                // Call.write_content( this.ns, this.owner_class_name, writer, class_data, "constructor", constructor.get_constructor_param_str(), "", comment, depth );
                // writer.add_code( format( "LD %s, %s ; %s", this.register_name, class_data.get_data_label(), comment ), depth );
            }
*/
        } else {
            throw new Exception( format( "Invalid register 16 load '%s' : ( %s )", right_var_data.classinfo.name, comment ) );
        }
    }

//    private string get_temp_obj_data_label( string class_name ) {
//        return format( "Temp_%d_Object_%s_Data", ++this.counter, class_name );
//    }

}
