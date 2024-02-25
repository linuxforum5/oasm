/**
 * Értékadás egy oldalának adattípusa
 */
import std.stdio;
import std.string;
import Namespace:Namespace;
import AsmWriter:AsmWriter;

class VariableData {

    protected Namespace ns;
    protected string owner_class_name;

    this( Namespace ns, string owner_class_name ) { // Left or right side
        this.ns = ns;
        this.owner_class_name = owner_class_name;
    }

    public void load_value_from( AsmWriter writer, VariableData value, string comment, uint depth ) {
        throw new Exception( format( "Ennek az objektumnak nem hívható meg a load_value_from művelete: '%s'", this.classinfo.name ) );
    }

}
