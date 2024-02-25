import std.stdio;
import std.string;
import Namespace:Namespace;
import AsmWriter:AsmWriter;
import Call:Call;
import ClassProperty:ClassProperty;
import ClassMethod:ClassMethod;
import PropertyDirect:PropertyDirect;
import PropertyIndexed:PropertyIndexed;

class ClassData {

    private string class_name;
    private string parent_class_name;
    private uint data_size;
    private ClassProperty[ string ] properties;
    private ClassMethod[ string ] methods;
    private Namespace ns;
    public uint child_counter = 0;

    this( Namespace ns, string class_name, string parent_class_name, uint data_size ) {
        this.ns = ns;
        this.class_name = class_name;
        this.parent_class_name = parent_class_name;
        this.data_size = data_size;
    }

    public ClassData get_parent_class_data() {
        if ( this.parent_class_name.length > 0 ) {
            return this.ns.get_class_data( this.parent_class_name );
        } else {
            throw new Exception( format( "No parent class found for class '%s'", this.class_name ) );
        }
    }

    public void add_method( string method_name, string param_str ) {
        this.add_method_data( new ClassMethod( this.class_name, method_name, param_str, this.multi_instance() ) );
    }
    protected void add_method_data( ClassMethod method_data ) { this.methods[ method_data.get_method_name() ] = method_data; }

    public void add_property( string property_name, string type ) {
        uint size = 0;
        if ( type == "DW" ) size = 2;
        if ( type == "DB" ) size = 1;
        if ( size == 0 ) throw new Exception( format( "Invalid property type '%s' for '%s.%s'", type, this.class_name, property_name ) );
        string index_register_name = this.get_index_register_name(); // Ha üres, akkor direct memory
        if ( index_register_name.length > 0 ) {
            this.add_property_data( new PropertyIndexed( index_register_name, this.class_name, property_name, this.data_size, size ) );
        } else {
            this.add_property_data( new PropertyDirect( this.ns, this.class_name, property_name, this.data_size, size ) );
        }
        this.data_size += size;
    }

    private void add_property_data( ClassProperty property_data ) {
        string property_name = property_data.get_property_name();
        if ( property_name in this.properties ) throw new Exception( format( "Property already defined : '%s'", property_name ) );
        this.properties[ property_name ] = property_data;
    }

    protected string get_index_register_name() {
        if ( this.parent_class_name == "PropertiesDirect" ) {
            return "";
        } else if ( this.parent_class_name == "PropertiesIX" ) {
            return "IX";
        } else if ( this.parent_class_name == "PropertiesIY" ) {
            return "IY";
        } else if ( this.parent_class_name.length > 0 ) {
            ClassData parent = this.ns.get_class_data( this.parent_class_name );
            return parent.get_index_register_name();
        } else {
            throw new Exception( "Invalid parent class!" );
        }
    }

    public uint get_class_data_size() { return this.data_size; }

    public void gen_class_method_call_code( AsmWriter writer, string owner_class_name, string method_name, string param_str, string if_str, string comment, uint depth ) {
        Call.write_content( this.ns, owner_class_name, writer, this, method_name, param_str, if_str, comment, depth );
        // string label = this.get_method_label( method_name );
        // writer.add_code( format( "CALL %s ; %s", label, comment ) );
    }

    public void gen_object_selector_code( AsmWriter writer, string object_data_label, string comment, uint depth ) {
        if ( this.parent_class_name.length > 0 ) {
            ClassData parent = this.ns.get_class_data( this.parent_class_name );
            return parent.gen_object_selector_code( writer, object_data_label, comment, depth );
        } else {
            throw new Exception( format( "No parent class found for class '%s'", this.class_name ) );
        }
    }

    public string get_method_label( string method_name ) {
        ClassMethod method = this.get_method_data( method_name );
        return method.get_method_label();
    }

    public bool is_method( string method_name ) {
        if ( method_name in this.methods ) {
            return true;
        } else if ( this.parent_class_name.length > 0 ) {
            return this.ns.get_class_data( this.parent_class_name ).is_method( method_name );
        } else {
            return false;
        }
    }

    public ClassMethod get_method_data( string method_name ) {
        if ( method_name in this.methods ) {
            return this.methods[ method_name ];
        } else if ( this.parent_class_name.length > 0 ) {
            return this.ns.get_class_data( this.parent_class_name ).get_method_data( method_name );
        } else {
            throw new Exception( format( "Method not found : '%s'", method_name ) );
        }
    }

    public string get_class_name() { return this.class_name; }

    public ClassProperty get_property_data( string property_name ) {
        if ( property_name in this.properties ) {
            return this.properties[ property_name ];
        } else if ( this.parent_class_name.length > 0 ) {
            ClassData parent = this.ns.get_class_data( this.parent_class_name );
            return parent.get_property_data( property_name );
        } else {
            throw new Exception( format( "Property not found: '%s'", property_name ) );
        }
    }

    public void check_object_address( AsmWriter writer, string get_object_data_label ) {
        // Ez IX és IY indexelt objektumok esetén ellenőrzi, hogy az IX vagy IY utoljára erre volt-e állítva
    }

    public bool multi_instance() {
        if ( this.parent_class_name.length > 0 ) {
            ClassData parent = this.ns.get_class_data( this.parent_class_name );
            return parent.multi_instance();
        } else {
            throw new Exception( format( "No parent class found for class '%s'", this.class_name ) );
        }
    }

    public string get_new_object_data_label( string object_name ) {
        return format( "Object_%s_in_Class_%s_Data", object_name, this.class_name );
    }

    public string get_method_definitor_class_name( string method_name ) {
        if ( method_name.length == 0 ) throw new Exception( "Empty method name not enabled!" );
        // writeln( format( "Seek method: '%s' in class '%s'", method_name, this.class_name ) );
        if ( method_name in this.methods ) {
            return this.class_name;
        } else if ( this.parent_class_name.length > 0 ) {
            ClassData parent = this.ns.get_class_data( this.parent_class_name );
            return parent.get_method_definitor_class_name( method_name );
        } else {
            throw new Exception( format( "Method not defined : '%s'", method_name ) );
        }
    }

    public string get_property_definitor_class_name( string property_name ) {
        if ( property_name.length == 0 ) throw new Exception( "Empty property name not enabled!" );
        if ( property_name in this.properties ) {
            return this.class_name;
        } else if ( this.parent_class_name.length > 0 ) {
            ClassData parent = this.ns.get_class_data( this.parent_class_name );
            return parent.get_property_definitor_class_name( property_name );
        } else {
            throw new Exception( format( "Property not defined : '%s'", property_name ) );
        }
    }

}
