//import std.file;
import std.stdio; //kiirashoz kell
import std.array;
import std.string;
import core.stdc.stdlib : exit;
import SourceReader:SourceReader;


class Debugger {

    protected static block_debug = false;
    protected static file_debug = false;
    // protected static class_debug = false;
    protected static object_debug = false;
    protected static gen_code_debug = false;
    public SourceReader reader;

    this( SourceReader reader ) {
        this.reader = reader;
    }

    protected void error( string msg ) {
        if ( this.reader.get_file_counter() > 0 ) {
// writef( "File counter: %d\n", this.file_counter );
            write( format( "Last line (%d. in file '%s'): '%s'\nError: %s\n", this.reader.get_line_number(), this.reader.get_filename(), this.reader.get_last_line(), msg ) );
//        printf( "HIBA:\n%s\n", msg.ptr );
        } else {
            write( format( "Last line (no opened file): '%s'\nError: %s\n", this.reader.get_last_line(), msg ) );
        }
        exit(1);
    }

    protected void info( string msg, uint depth = 0 ) {
        write( format( "%s%s\n", replicate( " ", depth*2 ), msg ) );
    }

    public void file_info( string msg, uint depth = 0 ) {
        if ( this.file_debug ) this.info( msg, depth );
    }

    public void block_info( string msg, uint depth = 0 ) {
        if ( this.block_debug ) this.info( msg, depth );
    }

    public void gen_info( string msg, uint depth = 0 ) {
        if ( this.gen_code_debug ) this.info( msg, depth );
    }

    public void obj_info( string msg, uint depth = 0 ) {
        if ( this.object_debug ) this.info( msg, depth );
    }

}
