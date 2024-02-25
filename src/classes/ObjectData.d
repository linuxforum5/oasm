import std.string;
import std.stdio;
import ClassData:ClassData;
import AsmWriter:AsmWriter;
import VariableData:VariableData;
import ClassProperty:ClassProperty;

class ObjectData {

    private string name;
    private ClassData class_data;
    private string data_label;
    private static temp_boject_counter = 0;

    this( string name, ClassData class_data ) {
        if ( class_data is null ) throw new Exception( format( "Új objektum nem hozható létre null osztállyal: '%s'", name ) );
        if ( name.length == 0 ) name = format( "TempObject%d", ++this.temp_boject_counter );
        this.name = name;
        this.class_data = class_data;
        if ( class_data.multi_instance() ) { // Ennek az osztálynak lehet több objektuma is, így memóriát kell allokálni az egyes példányok számára
            this.data_label = class_data.get_new_object_data_label( name );
        } else {
            this.data_label = ""; // Csak multi instance class esetén van értéke // "undefinde data label with single instance class";
        }
    }

    public void gen_object_method_call_code( AsmWriter writer, string owner_class_name, string method_name, string param_str, string if_str, string comment, uint depth ) {
////writeln( format( "OBJ: %s: '%s'", comment, this.class_data.classinfo.name ) );
//if ( this.class_data.multi_instance() ) writeln( "*************" );
        string label = this.get_object_data_label();
        this.class_data.gen_object_selector_code( writer, label, comment, depth );
        this.class_data.gen_class_method_call_code( writer, owner_class_name, method_name, param_str, if_str, comment, depth );
    }

    public ClassData get_class_data() { return this.class_data; }

    public string get_object_data_label() {
        return this.data_label;
//        return format( "Object_%s_in_Class_%s_Data", this.name, this.class_data.get_class_name() );
    }

    public void set_class_data( ClassData class_data ) {
        if ( this.class_data is null ) {
            this.class_data = class_data;
        } else {
            if ( this.class_data.classinfo.name != class_data.classinfo.name ) throw new Exception( "Object class missmatch" );
        }
    }

    public void set_data_label( string data_label ) {
        if ( this.data_label.length > 0 ) throw new Exception( "Object data label already defined!" );
        this.data_label = data_label;
    }
    public string get_data_label() { return this.data_label; }

    public ClassProperty get_property_data( AsmWriter writer, string property_name ) {
        if ( this.class_data is null ) throw new Exception( "Az objektum osztálya null!" );
        this.class_data.check_object_address( writer, this.get_object_data_label ); // Ha ez egy mult objektum, akkor az IX vagy IY ellenőrzése, hogy valóban az obejktumra mutat-e. Ha nem, beállítjuk
        return this.class_data.get_property_data( property_name );
    }

}
