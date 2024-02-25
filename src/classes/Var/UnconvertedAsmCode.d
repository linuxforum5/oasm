/**
 * Értékadás egy oldalának adattípusa
 */
import std.stdio;
import std.regex;
import Namespace:Namespace;
import VariableData:VariableData;

class UnconvertedAsmCode : VariableData {

    private string asm_code;

    this( Namespace ns, string owner_class_name, string asm_code ) {
        super( ns, owner_class_name );
        this.asm_code = asm_code;
    }

    public string get_asm_code() { return this.asm_code; }

}
