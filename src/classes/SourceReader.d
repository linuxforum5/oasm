import std.file;
import std.string;
import std.algorithm;
import std.regex;
import std.stdio; //kiirashoz kell
// import std.string;

class SourceReader {

    private string[] filenames;
    private int[] line_numbers;
    private File*[] files;    // A megnyitott fájlok
    private int file_counter; // A megnyitott fájlok számát tárolja
    private string last_line;

    this( string first_filename ) {
        this.filenames = [];
        this.line_numbers = [];
        this.file_counter = 0;
        this.last_line = "";
        this.open_new_source_file( first_filename );
    }


    public int get_file_counter() { // A megnyitott - és még le nem zárt - fájlok száma
        return this.file_counter;
    }

    public void open_new_source_file( string sourceFilename ) { // Megynit egy új fájlt. Hiba esetén megáll
        if ( std.file.exists( sourceFilename ) ) {
            this.filenames ~= sourceFilename;
            this.line_numbers ~= 0;
            this.files ~= new File( sourceFilename );
            this.file_counter++;
        } else {
            throw new Exception( format( "File '%s' not found!", sourceFilename ) );
        }
    }
    
    public string read_line() { // Az utoljára megynitott fájlból olvas egy sort, és ezt visszaadja
        if ( this.eof() ) throw new Exception( "EOF2!" );
        string line = this.files[ this.file_counter-1 ].readln();
        this.last_line = strip( line.replaceAll( regex( r";.*$", "gm" ), "" ) );
        return this.last_line;
    }
    
    public bool eof() { // Az utoljára megynitott fájlból olvas egy sort, és ezt visszaadja
        return this.files[ this.file_counter-1 ].eof();
    }
    
    public void close_last_source_file() { // Az utoljára megynitott fájl lezárása
        this.files[ --this.file_counter ].close();
        this.files = this.files.remove( this.file_counter );
        this.line_numbers = this.line_numbers.remove( this.file_counter );
        this.filenames = this.filenames.remove( this.file_counter );
    }
    
    public int get_line_number() { // Az utoljára megnyitott fájlban az aktuális sor száma, hibakezeléshez
        return this.line_numbers[ this.file_counter-1 ];
    }
    
    public string get_filename() { // Az utoljára megynitott fájl neve, hibakezeléshez
        return this.filenames[ this.file_counter-1 ];
    }
    
    public string get_last_line() {
        return this.last_line;
    }

}
