/**
 * Egy köztes if ága vége. else if
 */
import std.stdio;
import std.string;
import std.regex;
import EndBlock:EndBlock;
import Namespace:Namespace;

class EndUntil : EndBlock {

    public static EndUntil it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^\}\s*until\s*\((.*)\)$" ) ) { // else | elseif | else if
            string condition = m[1];
            return new EndUntil( ns, depth, line, owner_class_name, condition );
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
