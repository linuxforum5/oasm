/**
 * Az értékadás jobb oldalán álló string konstans idézőjelek között
 */
import std.stdio;
import std.string;
import std.regex;
import Namespace:Namespace;
import ClassData:ClassData;
import VariableData:VariableData;

class StringConstant : VariableData {

    private static uint counter = 0;

    public static StringConstant it_is_this( Namespace ns, string owner_class_name, string side ) {
        if ( auto m = std.regex.matchFirst( side, r"^\x22(.*)\x22$" ) ) { // "string constant"
            string string_content = m[1];
            return new StringConstant( ns, owner_class_name, string_content );
        } else {
            return null;
        }
    }

    private string string_content;
    private string data_label;

    this( Namespace ns, string owner_class_name, string string_content ) {
        super( ns, owner_class_name );
        this.string_content = string_content;
        this.data_label = format( "String_constant_%d_Data", ++this.counter );
    }

    public string get_string_data_label() { return this.data_label; }
    public string get_string_content() { return this.string_content; }

}
