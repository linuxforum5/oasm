import std.string;
import AsmWriter:AsmWriter;
import VariableData:VariableData;
import Property:Property;
import Register8bit:Register8bit;
import Register16bit:Register16bit;
import UnconvertedAsmCode:UnconvertedAsmCode;

class ClassProperty {

    protected string owner_class_name; // Egy címke, ami vagy egy memóriacímet azonosít, vagy egy konstanst
    protected string property_name;
    protected ulong shift0;
    protected uint size;            // A property mérete. Egyelőre 1 vagy 2
    protected string type = "";

    this( string owner_class_name, string property_name, ulong shift0, uint size ) {
        this.owner_class_name = owner_class_name;
        this.property_name = property_name;
        this.shift0 = shift0;
        this.size = size;
    }

    abstract public void load_value_from( AsmWriter writer, VariableData value, uint byte_address, string comment, uint depth );
    abstract public void load_value_into( AsmWriter writer, VariableData value, uint byte_address, string comment, uint depth );
    abstract public void inc_dec( AsmWriter writer, string inc_dec_cmd_prefix, uint byte_address, string comment, uint depth );

    public string get_property_name() { return this.property_name; }
    public string get_property_def_label() { return format( "Class_%s_%sProperty_%s_Shift_%d_Size_%s_Data", this.owner_class_name, this.type, this.property_name, this.shift0, this.size ); }
    public string get_property_use_label( uint byte_address ) {
        if ( byte_address > 0 ) {
            return format( "%s + %d", this.get_property_def_label(), byte_address );
        } else {
            return this.get_property_def_label();
        }
    }
    public ulong get_property_shift0() { return this.shift0; }

    public uint get_property_size() { return size; }

}
