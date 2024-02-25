/**
 * Értékadás egy oldalának adattípusa
 */
import std.stdio;
import std.string;
import std.regex;
import Namespace:Namespace;
import VariableData:VariableData;
import AsmWriter:AsmWriter;
import Property:Property;
import ClassProperty:ClassProperty;
import Register16bit:Register16bit;
import StringConstant:StringConstant;
import UnconvertedAsmCode:UnconvertedAsmCode;

class Register8bit : VariableData {

    public static Register8bit it_is_this( Namespace ns, string owner_class_name, string side ) {
        if ( auto m = std.regex.matchFirst( side, r"^([ABCDEHLIR])$" ) ) {
            string register_name = m[1];
            return new Register8bit( ns, owner_class_name, register_name );
        } else {
            return null;
        }
    }

    private string register_name;

    this( Namespace ns, string owner_class_name, string register_name ) {
        super( ns, owner_class_name );
        this.register_name = register_name;
    }

    public string get_register_name() { return this.register_name; }

    override public void load_value_from( AsmWriter writer, VariableData right_var_data, string comment, uint depth ) {
        if ( Property v = cast(Property)right_var_data ) {
            ClassProperty prop = v.get_property_data( writer, comment );
            prop.load_value_into( writer, this, v.get_byte_address(), comment, depth );
        } else if ( Register16bit v = cast(Register16bit)right_var_data ) {
            throw new Exception( format( "8 bites registerbe nem tölthető 16 bites regiszter!" ) );
        } else if ( Register8bit v = cast(Register8bit)right_var_data ) {
            if ( v.get_register_name() != this.get_register_name() ) {
                writer.add_code( format( "LD %s, %s ; %s", this.register_name, v.get_register_name(), comment ), depth );
            }
        } else if ( StringConstant v = cast(StringConstant)right_var_data ) {
            throw new Exception( format( "8 bites registerbe nem tölthető String constant!" ) );
        } else if ( UnconvertedAsmCode v = cast(UnconvertedAsmCode)right_var_data ) {
            writer.add_code( format( "LD %s, %s ; %s", this.register_name, v.get_asm_code(), comment ), depth );
        } else {
            throw new Exception( format( "Ivalid register 8 load!" ) );
        }
    }

}
