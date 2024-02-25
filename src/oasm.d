/**
 * Object Assembler fordító
 */
import std.stdio;
import core.stdc.stdlib : exit;
import Converter:Converter;

void help() {
    writeln( "oasm V.:0.2.2" );
    writeln( "Object Assembler  for Z80." );
    writeln( "Use:" );
    writeln( "oasm oasm_source_directory source" );
    writeln( "- oa_source_directory: oasm and asm files root directory" );
    writeln( "- source: main oasm filename without .oasm extension" );
}

void convert( string base_dir_name, string src, string dest ) {
    try {
        Converter conv = new Converter( base_dir_name, src );
        conv.convert( dest );
    } catch ( Exception e ) {
        writeln( e );
        exit( 1 );
    }
}

int main( string[] args ) {
    string filename;
    if ( args.length == 3 ) {
        string dir_name = args[ 1 ];
        string src = args[ 2 ] ~ ".oasm";
        string dest = args[ 2 ] ~ ".asm";
        writef( "Start conversion from '%s' to '%s' ...\n", src, dest );
        convert( dir_name, dir_name ~ "/" ~ src, dir_name ~ "/" ~ dest );
        writef( "Conversion finished\n" );
    } else {
        help();
    }
    return 0;
}
