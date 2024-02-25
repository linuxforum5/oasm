/**
 * Egy köztes if ága vége. else if
 */
import std.stdio;
import std.regex;
import EndBlock:EndBlock;
import Namespace:Namespace;

class EndIfElseLine : EndBlock {

    public static EndIfElseLine it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^\}\s*else\s*(|if\s*\((.*)\))\s*\{$" ) ) { // else | elseif | else if
            string condition = m[2];
            return new EndIfElseLine( ns, depth, line, owner_class_name, condition );
        } else {
            return null;
        }
    }

    public string condition;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string condition ) {
        super( ns, depth, origi_line, owner_class_name );
        this.condition = condition;
    }

}
