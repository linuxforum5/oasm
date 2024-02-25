import std.regex;
import std.string;
import MultiBlock:MultiBlock;
import EndUntil:EndUntil;
import Namespace:Namespace;
import Block:Block;
import AsmWriter:AsmWriter;
import Condition:Condition;

class Until : MultiBlock {

    public static Until it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^\{$" ) ) { // while() {
            return new Until( ns, depth, line, owner_class_name );
        } else {
            return null;
        }
    }

    private static uint counter = 0;
    private string condition;
    private string begin_label;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name ) {
        super( ns, depth, origi_line, owner_class_name );
        this.begin_label = format( "Class_%s_Until_%d_Begin", owner_class_name, ++this.counter );
        Block block = ns.read_next_block( depth + 1, this.owner_class_name );
        while( !cast( EndUntil ) block ) { // Addig megy, míg a beolvasott blokk nem valamilyen EndBlokk vagy leszármazottja
            this.add_block( block );
            block = ns.read_next_block( depth + 1, this.owner_class_name );
        }
        this.condition = (cast(EndUntil)block).condition;
    }

    override public void convert_content( AsmWriter writer ) {
        writer.add_code_label( this.begin_label, format( "; Until begin : %s", this.origi_line ), this.depth );
        super.convert_content( writer );
//        if ( this.condition.length > 0 ) {
            new Condition( this.condition ).not().write_jump( writer, this.begin_label, this.origi_line, this.depth, "JP" );
//        } else { // Forever loop
//            writer.add_code( format( "JP %s ; %s", this.begin_label, this.origi_line ), this.depth );
//        }
    }

}
