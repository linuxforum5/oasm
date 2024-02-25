/**
 * Értékadás egy oldalának adattípusa
 */
import std.stdio;
import std.regex;
import Namespace:Namespace;
import VariableData:VariableData;
import ClassData:ClassData;

class CallClassConstructor : VariableData {

    public static CallClassConstructor it_is_this( Namespace ns, string owner_class_name, string side ) {
        if ( auto m = std.regex.matchFirst( side, r"^new\s+([^\s]+)\((.*)\)$" ) ) { // new class()
            string new_class_name = m[1];
            string new_param_str = m[2];
            return new CallClassConstructor( ns, owner_class_name, new_class_name, new_param_str );
        } else {
            return null;
        }
    }

    private string new_class_name;
    private string new_param_str;

    this( Namespace ns, string owner_class_name, string new_class_name, string new_param_str ) {
        super( ns, owner_class_name );
        this.new_class_name = new_class_name;
        this.new_param_str = new_param_str;
        if ( !ns.is_class( new_class_name ) ) ns.load_class( new_class_name );
    }

    public ClassData get_class_data() {
        return this.ns.get_class_data( this.new_class_name );
    }

    public string get_class_name() { return this.new_class_name; }

    public string get_constructor_param_str() {
        return this.new_param_str;
    }

}
