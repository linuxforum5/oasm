import std.string;
import AsmWriter:AsmWriter;
import VariableData:VariableData;
import Property:Property;
import Register8bit:Register8bit;
import Register16bit:Register16bit;
import StringConstant:StringConstant;
import UnconvertedAsmCode:UnconvertedAsmCode;
import ClassProperty:ClassProperty;

class PropertyIndexed : ClassProperty {

    // label = A kezdőcímtől való eltolás mértéke bájtokban. Egy címke, aminek az értéke az eltolás (EQU)
    private string base_index_register_name; // IX vagy IY

    this( string base_index_register_name, string owner_class_name, string property_name, ulong shift0, uint size ) {
        super( owner_class_name, property_name, shift0, size );
        this.base_index_register_name = base_index_register_name;
        this.type = "Indexed" ~ base_index_register_name;
    }

    /**
     * Feltételezzük, hogy az IX vagy IY értéke megfelelő
     */
    override public void load_value_from( AsmWriter writer, VariableData value, uint byte_address, string comment, uint depth ) {
        if ( cast(Property)value ) {
            throw new Exception( "Invalid value load from Property into indexed property" );
        } else if ( Register8bit v = cast(Register8bit)value ) {
            if ( this.size == 1 ) {
                writer.add_code( format( "LD (%s+%s), %s ; %s", this.base_index_register_name, this.get_property_use_label( byte_address ), v.get_register_name(), comment ), depth );
            } else {
                throw new Exception( "Size missmatch error" );
            }
        } else if ( cast(Register16bit)value ) {
            Register16bit v = cast(Register16bit)value;
            if ( this.size == 2 ) {
                writer.add_code( format( "LD (%s+%s), %c ; %s", this.base_index_register_name, this.get_property_use_label( byte_address ), v.get_register_name_last_character(), comment ), depth );
                writer.add_code( format( "LD (%s+%s), %c ; %s", this.base_index_register_name, format( "%s+1", this.get_property_use_label( byte_address ) ), v.get_register_name_first_character(), comment ), depth );
            } else {
                throw new Exception( "Size missmatch error" );
            }
        } else if ( StringConstant v = cast(StringConstant)value ) {
            if ( this.size == 2 ) {
                // writer.add_code( format( "LD A, %s ; %s", format( "%s %% 256", v.get_string_data_label() ), comment ), depth );
                // writer.add_code( format( "LD A, %s ; %s", format( "%s / 256", v.get_string_data_label() ), comment ), depth );
                string data_label_low = format( "%s %% 256", v.get_string_data_label() );
                string data_label_high = format( "%s / 256", v.get_string_data_label() );
                writer.add_code( format( "LD (%s+%s), %s ; %s", this.base_index_register_name, this.get_property_use_label( byte_address ), data_label_low, comment ), depth );
                writer.add_code( format( "LD (%s+%s), %s ; %s", this.base_index_register_name, format( "%s+1", this.get_property_use_label( byte_address ) ), data_label_high, comment ), depth );
                writer.add_data( v.get_string_data_label(), format( "DB \"%s\",0 ; %s", v.get_string_content(), comment ), this.size );
            } else {
                throw new Exception( "Size missmatch error" );
            }
        } else if ( UnconvertedAsmCode v = cast(UnconvertedAsmCode)value ) {
            writer.add_code( format( "LD (%s+%s), %s ; %s", this.base_index_register_name, this.get_property_use_label( byte_address ), v.get_asm_code(), comment ), depth );
        } else {
            throw new Exception( "Invalid value load into indexed property" );
        }
    }

    override public void load_value_into( AsmWriter writer, VariableData value, uint byte_address, string comment, uint depth ) {
        if ( cast(Property)value ) {
            throw new Exception( "Invalid value load into Property from indexed property" );
        } else if ( Register8bit v = cast(Register8bit)value ) {
            if ( this.size == 1 ) {
                if ( byte_address != 0 ) throw new Exception( "Invalid byte address" );
                writer.add_code( format( "LD %s, (%s+%s) ; %s", v.get_register_name(), this.base_index_register_name, this.get_property_use_label( byte_address ), comment ), depth );
            } else if ( byte_address == 1 ) {
                writer.add_code( format( "LD %s, (%s+%s) ; %s", v.get_register_name(), this.base_index_register_name, this.get_property_use_label( byte_address ), comment ), depth );
            } else {
                throw new Exception( "Size missmatch error" );
            }
        } else if ( cast(Register16bit)value ) {
            Register16bit v = cast(Register16bit)value;
            if ( this.size == 2 ) {
                if ( byte_address != 0 ) throw new Exception( "Invalid byte address" );
                writer.add_code( format( "LD %c, (%s+%s) ; %s", v.get_register_name_last_character(), this.base_index_register_name, this.get_property_use_label( byte_address ), comment ), depth );
                writer.add_code( format( "LD %c, (%s+%s) ; %s", v.get_register_name_first_character(), this.base_index_register_name, this.get_property_use_label( byte_address + 1 ), comment ), depth );
            } else {
                throw new Exception( "Size missmatch error" );
            }
        } else if ( UnconvertedAsmCode v = cast(UnconvertedAsmCode)value ) {
            throw new Exception( "Invalid value load from indexed property" );
        } else {
            throw new Exception( "Invalid value load from indexed property" );
        }
    }

    override public void inc_dec( AsmWriter writer, string inc_dec_cmd_prefix, uint byte_address, string comment, uint depth ) {
        if ( byte_address != 0 ) throw new Exception( "Byte address in inc or dec!" );
        writer.add_code( format( "%s (%s+%s) ; %s", inc_dec_cmd_prefix, this.base_index_register_name, this.get_property_use_label( byte_address ), comment ), depth );
    }

}
