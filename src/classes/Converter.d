import std.stdio;
import std.string;
import Namespace:Namespace;
import Block:Block;
import AsmWriter:AsmWriter;
import SourceReader:SourceReader;

class Converter {

    private Namespace ns;
    private Block[] blocks;
    private SourceReader reader;

    this( string base_dir_name, string src ) {
        this.reader = new SourceReader( src );
        this.blocks = [];
        // this.ns = new Namespace( &this.blocks, this.reader, base_dir_name, new AsmWriter() );
        this.ns = new Namespace( this.reader, base_dir_name, new AsmWriter() );
    }

    public void convert( string destFilename ) {
        while( !this.ns.eof() ) {
            this.blocks ~= ns.read_next_block( 0, "" );
        }
        this.reader.close_last_source_file();
        // Append class codes
        Block[] loaded_blocks = this.ns.get_loaded_blocks();
        foreach ( Block block; loaded_blocks ) {
            this.blocks ~= block;
        }
        // Optimize ...
//        Optimizer optimizer = new Optimizer();
//        foreach ( Block block; this.blocks ) {
//            optimizer.optimize( block );
//        }
        // Generate code
        foreach ( Block block; this.blocks ) {
            this.ns.debugger.gen_info( format( "Convert block '%s' ; %s", block.classinfo.name, block.get_origi_line() ), block.get_depth() );
            this.ns.writer.set_class_mode( block.is_in_class_mode() );
            block.convert_content( this.ns.writer );
        }
        this.ns.last_check();
        this.ns.writer.save( destFilename );
    }

}
