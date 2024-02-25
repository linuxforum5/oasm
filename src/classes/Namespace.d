import std.stdio;
import std.string;
import std.algorithm;
import ObjectData:ObjectData;
import ClassData:ClassData;
import SourceReader:SourceReader;
import Debugger:Debugger;
import Block:Block;
import EmptyLine:EmptyLine;
import UseClass:UseClass;
import Let:Let;
import Call:Call;
import EndBlock:EndBlock;
import EndUntil:EndUntil;
import EndIfElseLine:EndIfElseLine;
import If:If;
import While:While;
import Break:Break;
import ForB:ForB;
import Until:Until;
import UnconvertedAsmLine:UnconvertedAsmLine;
import EOF:EOF;
import AsmWriter:AsmWriter;
import Class:Class;
import IncDec:IncDec;
import PropertyDef:PropertyDef;
import MethodDef:MethodDef;
import PropertiesDirect:PropertiesDirect;
import PropertiesIX:PropertiesIX;
import PropertiesIY:PropertiesIY;

class Namespace {

    private ObjectData[ string ] objects;
    private ClassData[ string ] classes;
    private SourceReader reader;
    public Debugger debugger;
    private string class_dir_name;
    public AsmWriter writer;
    // private Block[]* main_blocks;
    private Block[] loaded_blocks = [];
    private string[] break_labels = [];
    private uint[ string ] calls;
    private string[ string ] call_label;

    // this( Block[]* main_blocks, SourceReader reader, string class_dir_name, AsmWriter writer ) {
    this( SourceReader reader, string class_dir_name, AsmWriter writer ) {
        // this.main_blocks = main_blocks;
        this.reader = reader;
        this.debugger = new Debugger( reader );
        this.class_dir_name = class_dir_name;
        this.writer = writer;
        this.add_class_data( new PropertiesDirect( this ) );
        this.add_class_data( new PropertiesIX( this ) );
        this.add_class_data( new PropertiesIY( this ) );
        this.break_labels = [];
    }

    ///////////////////////////////////////////////////////////////////////////////////
    /// Break műveletek
    ///////////////////////////////////////////////////////////////////////////////////
    public string get_break_label() {
        if ( this.break_labels.length == 0 ) throw new Exception( "Break without label!" );
        return this.break_labels[ this.break_labels.length - 1 ];
    }
    public void open_break_label_block( string label ) {
        if ( label.length == 0 ) throw new Exception( "Empty break label!" );
        this.break_labels ~= label;
    }
    public void close_break_label_block( string label_for_check ) {
        if ( this.break_labels.length == 0 ) throw new Exception( "Close break block without open!" );
        if ( this.break_labels[ this.break_labels.length - 1 ] != label_for_check ) throw new Exception( "Invalid break block close!" );
        ulong index = this.break_labels.length - 1;
        this.break_labels = this.break_labels.remove( index );
    }

    public void last_check() {
        if ( this.break_labels.length != 0 ) throw new Exception( format( "Break block structure error: %d", this.break_labels.length ) );
    }

    ///////////////////////////////////////////////////////////////////////////////////
    /// Class és object műveletek
    ///////////////////////////////////////////////////////////////////////////////////
    public bool is_class( string class_name ) { return ( class_name in this.classes ) ? true : false; }
    public bool is_object( string object_name ) { return ( object_name in this.objects ) ? true : false; }
    public ClassData get_class_data( string class_name ) {
        if ( !this.is_class( class_name ) ) this.load_class( class_name );
        if ( this.is_class( class_name ) ) {
            return this.classes[ class_name ];
        } else {
            throw new Exception( format( "Class not exists '%s'", class_name ) );
        }
    }
    public ObjectData get_object_data( string object_name ) { return this.objects[ object_name ]; }
    public void add_class_data( ClassData class_data ) { this.classes[ class_data.get_class_name() ] = class_data; }
    public void add_object( string object_name, ObjectData object_data ) { this.objects[ object_name ] = object_data; }

    public SourceReader get_reader() { return this.reader; }

    public bool eof() { return this.reader.eof(); }
    public bool under_class_loading() { return this.reader.get_file_counter() > 1; }

    public Block read_next_block( uint depth, string owner_class_name, string owner_class_name_for_class = "" ) { // egymásbaágyazott class nem megengedett
        if ( !this.eof() ) {
            string line = this.reader.read_line();
            Block block = EmptyLine.it_is_this( this, depth, line, owner_class_name );
            while ( ( !this.eof() ) && ( block !is null ) ) {
                line = this.reader.read_line();
                block = EmptyLine.it_is_this( this, depth, line, owner_class_name );
            }
            if ( !this.eof() ) {
                if ( block is null ) block = UseClass.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = Let.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = Call.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = IncDec.it_is_this( this, depth, line, owner_class_name );

                if ( block is null ) block = EndBlock.it_is_this( this, depth, line, owner_class_name ); // class, method, simple if
                if ( block is null ) block = EndUntil.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = EndIfElseLine.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = Break.it_is_this( this, depth, line, owner_class_name );

                if ( block is null ) block = If.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = While.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = ForB.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = Until.it_is_this( this, depth, line, owner_class_name );
                if ( block is null ) block = Class.it_is_this( this, depth, line, owner_class_name_for_class );
                if ( owner_class_name.length > 0 ) {
                    if ( block is null ) block = MethodDef.it_is_this( this, depth, line, owner_class_name );
                    if ( block is null ) block = PropertyDef.it_is_this( this, depth, line, owner_class_name );
                }

                if ( block is null ) block = new UnconvertedAsmLine( this, depth, line, owner_class_name );

                return block;
            }
        }
        return new EOF( this, depth, this.reader.get_filename() );
    }

    public string get_filename() { return this.reader.get_filename(); }
    public int get_line_number() { return this.reader.get_line_number(); }

    public Block[] get_loaded_blocks() { return this.loaded_blocks; }

    public void load_class( string class_name ) {
        string class_filename = format( "%s/classes/%s.oasm", this.class_dir_name, class_name );
        this.debugger.file_info( format( "Load class file '%s'", class_filename ) );
        this.reader.open_new_source_file( class_filename );
//        Block[] blocks = [];
        while( !this.eof() ) {
            // *this.main_blocks ~= this.read_next_block( 0, "", class_name );
            this.loaded_blocks ~= this.read_next_block( 0, "", class_name );
        }
        this.reader.close_last_source_file();
        this.debugger.file_info( format( "Close class file '%s'", class_filename ) );
/*
        foreach ( Block block; blocks ) {
            this.debugger.gen_info( format( "*** Convert class block '%s' ; %s", block.classinfo.name, block.get_origi_line() ), block.get_depth() );
            block.convert_content( this.writer );
        }
*/
    }

    /******************************************************************************************************************
     * Optimalizációs műveletek
     ******************************************************************************************************************/
/*
    public void register_call( string method_label ) {
        string call_label = "AFTER_CALL_LABEL_" ~ method_label;
        if ( method_label in this.calls ) {
            this.calls[ method_label ]++;
        } else {
            this.calls[ method_label ] = 1;
        }
        this.call_label[ method_label ] = call_label;
        // write( format( "Call '%s' - '%d'\n", method_label, this.calls[ method_label ] ) );
    }
    public uint get_call_counter( string method_label ) {
        return ( method_label in this.calls ) ? this.calls[ method_label ] : 0;
    }
    public string get_last_call_label( string method_label ) {
        if ( method_label in this.call_label ) {
            return this.call_label[ method_label ];
        } else {
            return "";
//            throw new Exception( format( "No call label: '%s'", label ) );
        }
    }
*/
}
