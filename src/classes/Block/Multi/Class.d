import std.regex;
import std.string;
import MultiBlock:MultiBlock;
import EndBlock:EndBlock;
import Namespace:Namespace;
import Block:Block;
import ClassData:ClassData;
import AsmWriter:AsmWriter;
import PropertiesDirect:PropertiesDirect;
import PropertiesIX:PropertiesIX;
import PropertiesIY:PropertiesIY;

class Class : MultiBlock {

    public static Class it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^class\s+([^\s]+)\s+extends\s+([^\s]+)\s*\{$" ) ) { // class name extends parent {
            string class_name = m[1];
            string parent_class_name = m[2];
            return new Class( ns, depth, line, owner_class_name, class_name, parent_class_name );
        } else {
            return null;
        }
    }

    private string class_name;
    private string parent_class_name;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string class_name, string parent_class_name ) {
        super( ns, depth, origi_line, owner_class_name );
        this.class_name = class_name;
        this.parent_class_name = parent_class_name;
        ClassData parent = ns.get_class_data( parent_class_name );
        if ( parent.child_counter == 0 ) {
            parent.child_counter++;
        } else if ( parent.multi_instance() ) {
            parent.child_counter++;
        } else if ( parent_class_name == "PropertiesDirect" ) {
            parent.child_counter++;
        } else if ( parent.get_class_data_size() == 0 ) {
            parent.child_counter++;
        } else { // PropertiesDirect és már van egy leszármazottja
            //parent = this.clone_as_free_name();
            throw new Exception( format( "Egy adatokat tartalmazó PropertiesDirect osztálynak '%s' csak 1 leszármazottja lehet: '%s'", parent_class_name, class_name ) );
        }
        ns.add_class_data( new ClassData( ns, class_name, parent.get_class_name(), parent.get_class_data_size() ) );

//        string parent_root_class_name = parent.get_root_class_name();
/*
        if ( cast(PropertiesDirect)parent ) {
            ns.add_class_data( new PropertiesDirect( ns, class_name, parent_class_name ) );
        } else if ( cast(PropertiesIX)parent ) {
            ns.add_class_data( new PropertiesIX( ns, class_name, parent_class_name ) );
        } else if ( cast(PropertiesIY)parent ) {
            ns.add_class_data( new PropertiesIY( ns, class_name, parent_class_name ) );
        } else {
            throw new Exception( format( "Invalid root parent class '%s' for class '%s'", parent_class_name, class_name ) );
        }
*/
        this.load_blocks_to_EndBlock();
/*
        Block block = ns.read_next_block( depth + 1, this.owner_class_name );
        while( !cast(EndBlock)block ) { // Addig megy, míg a beolvasott blokk nem valamilyen EndBlokk vagy leszármazottja
            this.add_block( block );
            block = ns.read_next_block( depth + 1, this.owner_class_name );
        }
*/
    }

    override public void convert_content( AsmWriter writer ) {
        writer.add_empty_code_line();
        writer.add_code( ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;" );
        writer.add_code( format( "; %s", this.origi_line ) );
        writer.add_code( ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;" );
        super.convert_content( writer );
        writer.add_code( format( "; } ; End class %s", this.class_name ) );
    }

}
