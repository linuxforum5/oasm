import Namespace:Namespace;
import ClassData:ClassData;
import AsmWriter:AsmWriter;

class PropertiesDirect : ClassData {

    this( Namespace ns, string class_name = "PropertiesDirect", string parent_class_name = "" ) { super( ns, class_name, parent_class_name, 0 ); }

    override public bool multi_instance() { return false; }

    override public void gen_object_selector_code( AsmWriter writer, string object_data_label, string comment, uint depth ) {}

}
