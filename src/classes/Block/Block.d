import std.stdio;
import std.string;
import Namespace:Namespace;
import AsmWriter:AsmWriter;

class Block {

    protected Namespace ns;
    protected uint depth;
    protected string origi_line;
    protected string owner_class_name; // Annak az osztálynak a neve, aminek a definíciója éppen zajlik, amelyikhez ez a kód tartozik. Ha nincs ilyen, akkor üres string

    this( Namespace ns, uint depth, string origi_line, string owner_class_name ) {
        this.ns = ns;
        this.depth = depth;
        this.origi_line = origi_line;
        this.owner_class_name = owner_class_name;
        ns.debugger.block_info( format( "Begin block '%s' ; %s", this.classinfo.name, origi_line ), depth );
    }

    public bool is_in_class_mode() { return this.owner_class_name.length > 0; }

    public void convert_content( AsmWriter writer ) {
        this.ns.debugger.gen_info( format( "Convert block @TODO! '%s' ; %s", this.classinfo.name, this.get_origi_line() ), this.get_depth() );
        writer.add_code( format( "; @TODO : CODE from class %s ; %s", this.classinfo.name, this.origi_line ), this.depth );
    }

    public string get_origi_line() { return this.origi_line; }
    public string get_owner_classname() { return this.owner_class_name; } // for debug only

    public uint get_depth() { return this.depth; }

}
