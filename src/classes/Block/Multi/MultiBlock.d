import std.string;
import Block:Block;
import Namespace:Namespace;
import AsmWriter:AsmWriter;
import EndBlock:EndBlock;
import EOF:EOF;

class MultiBlock : Block {

    protected Block[] blocks;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name ) {
        super( ns, depth, origi_line, owner_class_name );
        this.blocks = [];
    }

    protected void add_block( Block block ) {
        if ( cast(EOF)block ) throw new Exception( format( "EOF in block! (%s)", this.ns.get_filename() ) );
        this.blocks ~= block;
    }

    override public void convert_content( AsmWriter writer ) {
        // this.ns.debugger.gen_info( format( "Convert multi block content '%s' ; %s", this.classinfo.name, this.get_origi_line() ), this.get_depth() );
        foreach ( Block block; this.blocks ) {
            block.convert_content( writer );
        }
    }

    protected Block get_last_block() { return this.blocks[ this.blocks.length - 1 ]; }

    protected void load_blocks_to_EndBlock() {
        Block block = ns.read_next_block( this.depth + 1, this.owner_class_name );
        while( !cast(EndBlock)block ) { // Addig megy, míg a beolvasott blokk nem valamilyen EndBlokk vagy leszármazottja
            this.add_block( block );
            block = this.ns.read_next_block( this.depth + 1, this.owner_class_name );
        }
    }

}
