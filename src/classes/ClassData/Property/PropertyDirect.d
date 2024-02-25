import std.string;
import AsmWriter:AsmWriter;
import VariableData:VariableData;
import Property:Property;
import Register8bit:Register8bit;
import Register16bit:Register16bit;
import StringConstant:StringConstant;
import UnconvertedAsmCode:UnconvertedAsmCode;
import ClassProperty:ClassProperty;
import Namespace:Namespace;
import CallClassConstructor:CallClassConstructor;
import DefineObject:DefineObject;
import ClassData:ClassData;
import ObjectData:ObjectData;

class PropertyDirect : ClassProperty {

    private Namespace ns;
    private ObjectData pointed_object;

    this( Namespace ns, string owner_class_name, string property_name, ulong shift0, uint size ) {
        super( owner_class_name, property_name, shift0, size );
        this.ns = ns;
        this.type = "Direct";
        this.pointed_object = null;
    }

    public ObjectData get_pointed_object() {
        if ( this.pointed_object is null ) {
            throw new Exception( "No pointed object defined! (Uninitialized object?)" );
        } else {
            return this.pointed_object;
        }
    }

    override public void load_value_from( AsmWriter writer, VariableData value, uint byte_address, string comment, uint depth ) {
        if ( cast(Property)value ) {
            // throw new Exception( format( "Invalid value load from Property into direct memory property 6: %s -- %s", value.toString(), comment ) );
            if ( this.size == 1 ) {
                Register8bit v = new Register8bit( this.ns, this.owner_class_name, "A" );
                v.load_value_from( writer, value, comment, depth );
                this.load_value_from( writer, v, byte_address, comment, depth );
            } else {
                // throw new Exception( format( "Invalid value load from Property into direct memory property 6: %s -- %s", value.toString(), comment ) );
                Register16bit v = new Register16bit( this.ns, this.owner_class_name, "HL" );
                v.load_value_from( writer, value, comment, depth );
                this.load_value_from( writer, v, byte_address, comment, depth );
                //v.load_value_into( writer, value, comment, depth );
                //this.load_value_into( writer, v, byte_address, comment, depth );
            }
        } else if ( Register8bit v = cast(Register8bit)value ) {
            if ( this.size == 1 ) {
                if ( v.get_register_name() == "A" ) {
                    writer.add_code( format( "LD (%s), %s ; %s", this.get_property_use_label( byte_address ), v.get_register_name(), comment ), depth );
                } else {
                    writer.add_code( format( "LD A, %s ; %s", v.get_register_name(), comment ), depth );
                    writer.add_code( format( "LD (%s), A ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                }
            } else {
                throw new Exception( format( "Size missmatch error 1: %s", comment ) );
            }
        } else if ( Register16bit v = cast(Register16bit)value ) {
            if ( this.size == 2 ) {
                writer.add_code( format( "LD (%s), %s ; %s", this.get_property_use_label( byte_address ), v.get_register_name(), comment ), depth );
            } else {
                throw new Exception( format( "Size missmatch error 2: %s", comment ) );
            }
        } else if ( StringConstant v = cast(StringConstant)value ) {
            if ( this.size == 2 ) {
                writer.add_code( format( "LD HL, %s ; %s", v.get_string_data_label(), comment ), depth );
                writer.add_code( format( "LD (%s), HL ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                writer.add_data( v.get_string_data_label(), format( "DB \"%s\",0 ; %s", v.get_string_content(), comment ), 1 );
            } else {
                throw new Exception( format( "Size missmatch error 3: %s", comment ) );
            }
        } else if ( UnconvertedAsmCode v = cast(UnconvertedAsmCode)value ) {
            // throw new Exception( "Invalid value load into direct memory property 1" );
            // UnconvertedAsmCode v = cast(UnconvertedAsmCode)value;
            if ( this.size == 1 ) {
                writer.add_code( format( "LD A, %s ; %s", v.get_asm_code(), comment ), depth );
                writer.add_code( format( "LD (%s), A ; %s", this.get_property_use_label( byte_address ), comment ), depth );
            } else if ( this.size == 2 ) {
                writer.add_code( format( "LD A, %s %% 256 ; %s", v.get_asm_code(), comment ), depth );
                writer.add_code( format( "LD (%s), A ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                writer.add_code( format( "LD A, %s / 256 ; %s", v.get_asm_code(), comment ), depth );
                writer.add_code( format( "LD (%s + 1), A ; %s", this.get_property_use_label( byte_address ), comment ), depth );
            } else {
                throw new Exception( "Invalid size direct memory property in load" );
            }
        } else if ( CallClassConstructor constructor = cast(CallClassConstructor)value ) {
            if ( this.size == 2 ) {
                ObjectData obj_data = DefineObject.generate_new_indexed_object_code( writer, this.ns, "", constructor, this.owner_class_name, comment, depth );
                writer.add_code( format( "LD HL, %s ; %s", obj_data.get_data_label(), comment ), depth );
                writer.add_code( format( "LD (%s), HL ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                if ( this.pointed_object is null ) {
                    this.pointed_object = obj_data;
                } else {
                    throw new Exception( format( "a pointerek - egyelőre - csak egyszer kaphatnak értéket! %s", comment ) );
                }
            } else {
                throw new Exception( format( "Pointer csak DW property lehet! %s", comment ) );
            }
        } else {
            throw new Exception( format( "Invalid value load into direct memory property class %s: %s", value.classinfo.name, comment ) );
        }
    }

    override public void load_value_into( AsmWriter writer, VariableData value, uint byte_address, string comment, uint depth ) {
        if ( cast(Property)value ) {
            throw new Exception( "Invalid value load fromdirect memory property into Property 4" );
        } else if ( Register8bit v = cast(Register8bit)value ) { // Két bájtos property címét is bele lehet tölteni egybájtos regiszterbe. Ekkor az első, azaz az alsó bájtja kerül bele! Ez hasznos lehet!
            if ( this.size == 1 || byte_address == 0 ) {
                if ( byte_address != 0 ) throw new Exception( "Byte address too big!" );
                if ( v.get_register_name() == "A" ) {
                    writer.add_code( format( "LD %s, (%s) ; %s", v.get_register_name(), this.get_property_use_label( byte_address ), comment ), depth );
                } else {
                    writer.add_code( format( "LD A, (%s) ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                    writer.add_code( format( "LD %s, A ; %s", v.get_register_name(), comment ), depth );
                }
            } else if ( byte_address == 1 ) {
                if ( v.get_register_name() == "A" ) {
                    writer.add_code( format( "LD %s, (%s) ; %s", v.get_register_name(), this.get_property_use_label( byte_address ), comment ), depth );
                } else {
                    writer.add_code( format( "LD A, (%s) ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                    writer.add_code( format( "LD %s, A ; %s", v.get_register_name(), comment ), depth );
                }
            } else {
                throw new Exception( format( "Size missmatch error 3: %s", comment ) );
            }
        } else if ( Register16bit v = cast(Register16bit)value ) {
            if ( this.size == 2 ) {
                if ( byte_address != 0 ) throw new Exception( "Byte address too big!" );
                writer.add_code( format( "LD %s, (%s) ; %s", v.get_register_name(), this.get_property_use_label( byte_address ), comment ), depth );
            } else {
                throw new Exception( format( "Size missmatch error 3: %s", comment ) );
            }
        } else if ( cast(UnconvertedAsmCode)value ) {
            throw new Exception( "Invalid value load into direct memory property 3" );
            // UnconvertedAsmCode v = cast(UnconvertedAsmCode)value;
            // writer.add_code( format( "LD (%s), %s ; %s", this.get_property_use_label( byte_address ), v.get_asm_code(), comment ) );
        } else {
            throw new Exception( "Invalid value load into direct memory property 5" );
        }
    }

    override public void inc_dec( AsmWriter writer, string inc_dec_cmd_prefix, uint byte_address, string comment, uint depth ) {
        if ( byte_address != 0 ) throw new Exception( "Byte address in inc or dec!" );
        if ( this.size == 1 ) {
            if ( ( inc_dec_cmd_prefix == "inc" ) || ( inc_dec_cmd_prefix == "dec" ) ) {
                writer.add_code( format( "LD A, (%s) ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                writer.add_code( format( "%s A ; %s", inc_dec_cmd_prefix.toUpper(), comment ), depth );
                writer.add_code( format( "LD (%s), A ; %s", this.get_property_use_label( byte_address ), comment ), depth );
            } else {
                writer.add_code( format( "LD HL, %s ; %s", this.get_property_use_label( byte_address ), comment ), depth );
                writer.add_code( format( "%s (HL) ; %s", inc_dec_cmd_prefix.toUpper(), comment ), depth );
            }
        } else if ( this.size == 2 ) {
            writer.add_code( format( "LD HL, (%s) ; %s", this.get_property_use_label( byte_address ), comment ), depth );
            writer.add_code( format( "%s HL ; %s", inc_dec_cmd_prefix.toUpper(), comment ), depth );
            writer.add_code( format( "LD (%s), HL ; %s", this.get_property_use_label( byte_address ), comment ), depth );
            writer.add_code( format( "LD A, H; %s", comment ), depth );
            writer.add_code( format( "OR L; %s",  comment ), depth );
        } else {
            throw new Exception( format( "Size missmatch error 6: %s", comment ) );
        }
    }

}
