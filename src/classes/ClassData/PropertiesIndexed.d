import std.stdio;
import std.string;
import Namespace:Namespace;
import ClassData:ClassData;
import AsmWriter:AsmWriter;

class PropertiesIndexed : ClassData {

    private string base_index_register;

    this( Namespace ns, string class_name, string base_index_register, string parent_class_name = "" ) {
        super( ns, class_name, parent_class_name, 0 );
        this.base_index_register = base_index_register;
    }

    override public void gen_object_selector_code( AsmWriter writer, string object_data_label, string comment, uint depth ) {
        writer.add_code( format( "LD %s, %s ; %s", base_index_register, object_data_label, comment ), depth );
    }

    override public bool multi_instance() { return true; }

}
