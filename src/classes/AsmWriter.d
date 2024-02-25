import std.stdio;
import std.array;
import std.string;
import SourceReader:SourceReader;

class AsmWriter {

    private string main_asm_code_source;
    private string class_code_source;
    private string data_source;
    private uint[ string ] data_labels;
    private bool class_mode;
    private uint size = 0;

    this() {
        this.class_mode = false;
    }

    private void add_main_code( string line ) {
        this.main_asm_code_source ~= line;
    }

    private void add_class_code( string line ) {
        this.class_code_source ~= line;
    }

    public void set_class_mode( bool class_mode ) { this.class_mode = class_mode; }

    public void add_code( string line, uint depth = 0 ) {
        if ( line.length > 0 ) {
            if ( this.class_mode ) {
                this.add_class_code( format( "%s%s\n", replicate( " ", depth*2 ), line ) );
            } else { // Main source code conversion
                this.add_main_code( format( "%s%s\n", replicate( " ", depth*2 ), line ) );
            }
        }
    }

    public void add_empty_code_line() {
        if ( this.class_mode ) {
            this.add_class_code( "\n" );
        } else { // Main source code conversion
            this.add_main_code( "\n" );
        }
    }

    public void add_code_label( string label, string code = "", uint depth = 0, bool new_line_prefix = false ) {
        if ( new_line_prefix ) this.add_empty_code_line();
        if ( code.length > 0 ) {
            this.add_code( format( "%s: %s", label, code ), depth );
        } else if ( label.length > 0 ) {
            this.add_code( format( "%s:", label ), depth );
        }
    }

    public void add_data( string label, string line, uint size ) {
        if ( line.length > 0 ) {
            if ( label in this.data_labels ) {
                this.data_labels[ label ]++;
            } else {
                this.data_labels[ label ] = 1;
                this.data_source ~= format( "%s: %s\n", label, line );
            }
            this.size += size;
        } else {
            throw new Exception( format( "Adattartalom nélküli címke: '%s'", label ) );
        }
    }

    public void save( string filename ) {
        writeln( format( "Data segment size: %d\n", this.size ) );
        File *destFile = new File( filename, "w" );
        destFile.write( ";;; Code segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n" );
        destFile.write( this.main_asm_code_source );

        destFile.write( "\n;;; Data segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n" );
        destFile.write( this.data_source );

        destFile.write( "\n;;; Class segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n" );
        destFile.write( this.class_code_source );

        destFile.write( ";;; End of file ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n" );
        destFile.write( "BOTTOM_OF_PROGRAM:\n" );
        destFile.close();
    }

}
