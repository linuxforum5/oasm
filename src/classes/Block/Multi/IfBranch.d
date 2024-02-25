import std.stdio;
import std.string;
import MultiBlock:MultiBlock;
import EndIfElseLine:EndIfElseLine;
import Namespace:Namespace;
import Block:Block;
import EndBlock:EndBlock;
import AsmWriter:AsmWriter;
import If:If;
import Condition:Condition;

class IfBranch : MultiBlock {
/*
    public static IfBranch it_is_this( Namespace ns, uint depth, string line ) {
        if ( auto m = std.regex.matchFirst( line, r"^if\s*\((.*)\)\s*\{$" ) ) {
            string condition = m[1];
            return new IfBranch( ns, depth, line, condition );
        } else {
            return null;
        }
    }
*/
    private static uint counter = 0;
    private string condition;
    private EndIfElseLine end_line_block;
    private If owner; // Az If, amihez tartozik
    private string begin_label;
    private string end_label;
    private bool it_is_the_last_branch = false;
    private bool long_jump = false;                 // Ha igaz, akkor JR helyett JP a kód

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string condition, bool long_jump, If owner ) {
        super( ns, depth, origi_line, owner_class_name );
        this.condition = condition;
        this.owner = owner;
        this.begin_label = format( "Class_%s_IfBranch_%d_Begin", owner_class_name, ++this.counter );
        this.end_label = format( "Class_%s_IfBranch_%d_End", owner_class_name, this.counter );
        this.long_jump = long_jump;
        Block block = ns.read_next_block( depth + 1, this.owner_class_name );
        while( !cast(EndBlock)block ) { // Addig megy, míg a beolvasott blokk nem valamilyen EndBlokk vagy leszármazottja
            this.add_block( block );
            block = ns.read_next_block( depth + 1, this.owner_class_name );
            if ( this.ns.eof() ) throw new Exception( "EOF in if branch" );
        }
        if ( cast(EndIfElseLine)block ) { // Ez egy else ág. Lehet else vagy else if, de a lényeg, hogy egy újabb if ág következik, ami ezzel a blokkal kezdődik
            this.end_line_block = cast(EndIfElseLine)block;
        } else {
            this.end_line_block = null;
        }
    }

    public void set_last() { this.it_is_the_last_branch = true; }
    public string get_begin_label() { return this.begin_label; }
    public string get_end_label() { return this.end_label; }
    public string get_full_end_label() { return this.owner.get_last_end_label(); }

    public IfBranch create_next_branch() {
        if ( this.end_line_block is null ) { // Nincs következő ág
            return null;
        } else { // Van következő ág
            return new IfBranch( this.ns, this.depth, this.end_line_block.get_origi_line(), this.owner_class_name, this.end_line_block.condition, this.long_jump, this.owner );
        }
    }

    private IfBranch get_next_branch() {
        return this.owner.get_next_branch( this.begin_label );
    }

    override public void convert_content( AsmWriter writer ) {
        writer.add_code_label( this.begin_label, format( "; %s", this.origi_line ), this.depth );
        if ( this.condition.length > 0 ) { // Van feltétel
            string next_label;
            if ( this.it_is_the_last_branch ) {
                next_label = this.end_label;
            } else {
                IfBranch next_branch = this.get_next_branch();
                if ( next_branch is null ) {
                    throw new Exception( "Next if branch not found!" );
                } else {
                    next_label = next_branch.get_begin_label();
                }
            }
            new Condition( this.condition ).not().write_jump( writer, next_label, this.origi_line, this.depth+1, "JP" );
        } // különben szabadon fut tovább
        super.convert_content( writer );
        if ( !this.it_is_the_last_branch ) {
            if ( this.long_jump ) {
                writer.add_code( format( "JP %s ; %s", this.get_full_end_label(), this.origi_line ), this.depth+1 );
            } else {
                writer.add_code( format( "JR %s ; %s", this.get_full_end_label(), this.origi_line ), this.depth+1 );
            }
        } else {
            writer.add_code_label( this.end_label, "; }", this.depth );
        }
    }

}
