import std.regex;
import std.string;
import MultiBlock:MultiBlock;
import EndBlock:EndBlock;
import Namespace:Namespace;
import Block:Block;
import Condition:Condition;
import AsmWriter:AsmWriter;

class While : MultiBlock {

    public static While it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^while\s*\((.*)\)\s*\{$" ) ) { // while() {
            string condition = m[1];
            return new While( ns, depth, line, owner_class_name, condition );
        } else {
            return null;
        }
    }

    private static uint counter = 0;
    private string condition;
    private string begin_label;
    private string end_label;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string condition ) {
        super( ns, depth, origi_line, owner_class_name );
        this.condition = condition;
        this.begin_label = format( "Class_%s_While_%d_Begin", owner_class_name, ++this.counter );
        this.end_label = format( "Class_%s_While_%d_End", owner_class_name, ++this.counter );
        ns.open_break_label_block( this.end_label );
        this.load_blocks_to_EndBlock();
/*
        Block block = ns.read_next_block( depth + 1, this.owner_class_name );
        while( !cast( EndBlock ) block ) { // Addig megy, míg a beolvasott blokk nem valamilyen EndBlokk vagy leszármazottja
            this.add_block( block );
            block = ns.read_next_block( depth + 1, this.owner_class_name );
        }
*/
        ns.close_break_label_block( this.end_label );
    }

    override public void convert_content( AsmWriter writer ) {
        writer.add_code_label( this.begin_label, format( "; %s", this.origi_line ), this.depth );
        new Condition( this.condition ).not().write_jump( writer, this.end_label, this.origi_line, this.depth+1, "JP" );
        super.convert_content( writer );
        writer.add_code( format( "JR %s ; } ", this.begin_label ), this.depth );
        writer.add_code_label( this.end_label, "", this.depth );
    }

}
