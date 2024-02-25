import std.regex;
import std.string;
import MultiBlock:MultiBlock;
import EndBlock:EndBlock;
import Namespace:Namespace;
import Block:Block;
import AsmWriter:AsmWriter;

class ForB : MultiBlock {

    public static ForB it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^for\s+B\s*=\s*([^\s]+)\s+to\s*1\s*\{$" ) ) { // for B = n to 0 {
            string from_value = m[1];
            return new ForB( ns, depth, line, owner_class_name, from_value );
        } else {
            return null;
        }
    }

    private static uint counter = 0;
    private string from_value;
    private string begin_label;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string from_value ) {
        super( ns, depth, origi_line, owner_class_name );
        this.from_value = from_value;
        this.begin_label = format( "Class_%s_ForB_%d_Begin", owner_class_name, ++this.counter );
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
        writer.add_code( format( "LD B, %s ; %s", this.from_value, this.origi_line ), this.depth );
        writer.add_code_label( this.begin_label, "", this.depth );
        super.convert_content( writer );
        writer.add_code( format( "DJNZ %s", this.begin_label ), this.depth );
    }

}
