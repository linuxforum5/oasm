import std.stdio;
import std.string;
import std.regex;
import MultiBlock:MultiBlock;
import EndBlock:EndBlock;
import Namespace:Namespace;
import Block:Block;
import AsmWriter:AsmWriter;
import ClassData:ClassData;

class MethodDef : MultiBlock {

    public static MethodDef it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^(constructor)\s*\((.*)\)\s*\{$" ) ) { // constructor() {
            string method_name = m[1];
            string param_str = m[2];
            return new MethodDef( ns, depth, line, owner_class_name, method_name, param_str );
        } else if ( auto m = std.regex.matchFirst( line, r"^(public|protected|private)\s+([^\s]+)\s*\((.*)\)\s*\{$" ) ) { // constructor() {
            string method_name = m[2];
            string param_str = m[3];
            return new MethodDef( ns, depth, line, owner_class_name, method_name, param_str );
        } else {
            return null;
        }
    }

    private string method_name;
    private string param_str;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string method_name, string param_str ) {
        super( ns, depth, origi_line, owner_class_name );
        this.method_name = method_name;
        this.param_str = param_str;

        ClassData owner_class_data = ns.get_class_data( owner_class_name );
        owner_class_data.add_method( method_name, param_str );

        this.load_blocks_to_EndBlock();
/*
        Block block = ns.read_next_block( depth + 1, this.owner_class_name );
        while( !cast( EndBlock ) block ) { // Addig megy, míg a beolvasott blokk nem valamilyen EndBlokk vagy leszármazottja
            this.add_block( block );
            block = ns.read_next_block( depth + 1, this.owner_class_name );
        }
*/
    }

    override public void convert_content( AsmWriter writer ) {
        writer.add_code_label( this.get_method_label(), format( "; %s", this.origi_line ), this.depth, true );
        super.convert_content( writer );
//        uint callcnt = this.ns.get_call_counter( this.get_method_label() );
//        if ( callcnt == 0 ) { // No call, no return
//            write( format( "No call: %s\n", this.get_method_label() ) );
//            writer.add_code( format( "; } - return without call" ), this.depth );
//        } else if ( callcnt == 1 ) {
//            string label = this.ns.get_last_call_label( this.get_method_label() );
//            writer.add_code( format( "JP %s ; } - return", label ), this.depth );
//        } else {
            writer.add_code( format( "RET ; }" ), this.depth );
//        }
    }

    private string get_method_label() { return this.get_owner_class_data().get_method_label( this.method_name ); }
    private ClassData get_owner_class_data() { return this.ns.get_class_data( this.owner_class_name ); }

}
