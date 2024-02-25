import std.regex;
import std.string;
import std.stdio;
import MultiBlock:MultiBlock;
import Namespace:Namespace;
import IfBranch:IfBranch;
import AsmWriter:AsmWriter;

class If : MultiBlock {

    public static If it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^(if|IF)\s*\((.*)\)\s*\{$" ) ) {
            bool long_jump = ( m[1] == "IF" );
            string condition = m[2];
            return new If( ns, depth, line, owner_class_name, condition, long_jump );
        } else {
            return null;
        }
    }

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string condition, bool long_jump ) {
        super( ns, depth, origi_line, owner_class_name );
        IfBranch first_branch = new IfBranch( ns, depth + 1, origi_line, owner_class_name, condition, long_jump, this );
        this.add_block( first_branch );
        for( IfBranch next_branch = first_branch.create_next_branch(); next_branch !is null; next_branch = next_branch.create_next_branch() ) {
            this.add_block( next_branch );
        }
        this.get_last_branch().set_last();
    }

    private IfBranch get_last_branch() {
        if ( IfBranch last = cast(IfBranch)this.get_last_block() ) {
            return last;
        } else {
            throw new Exception( "If-ben nem IfBranch!" );
        }
    }

    public string get_last_end_label() { return this.get_last_branch().get_end_label(); }

    override public void convert_content( AsmWriter writer ) {
        writer.add_code( format( "; Begin if " ), this.depth );
        super.convert_content( writer );
        writer.add_code( format( "; End full if" ), this.depth );
    }

    public IfBranch get_next_branch( string branch_begin_label ) {
        IfBranch next_branch = null;
        for( int i=0; ( i<this.blocks.length-1 ) && ( next_branch is null ); i++ ) {
            if ( IfBranch branch = cast(IfBranch)this.blocks[ i ] ) {
                if ( branch.get_begin_label() == branch_begin_label ) {
                    if ( cast(IfBranch)this.blocks[ i+1 ] ) {
                        next_branch = cast(IfBranch)this.blocks[ i+1 ];
                    } else {
                        throw new Exception( "Invalid If branch structure!" );
                    }
                }
            } else {
                throw new Exception( "Invalid If brancj structure!" );
            }
        }
        return next_branch;
    }

}
