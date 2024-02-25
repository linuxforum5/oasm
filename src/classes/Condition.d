import std.stdio;
import std.string;
import std.regex;
import AsmWriter:AsmWriter;

class Condition {

    private string condition;

    this( string condition ) {
        this.condition = strip( condition );
        // if ( condition.length == 0 ) throw new Exception( "Condition is empty!" );
    }

    public static string oasmFlagToAsmFlag( string flag ) {
        switch( flag ) {
            case "Z" : flag = "Z"; break;
            case "NZ" : flag = "NZ"; break;
            case "CY" : flag = "C"; break;
            case "NCY" : flag = "NC"; break;
            case "P" : flag = "M"; break;
            case "M" : flag = "P"; break;
            default : throw new Exception( format( "Invalid oasm flag : '%s'", flag ) );
        }
        return flag;
    }

    public Condition not() { return new Condition( this.not_str( this.condition ) ); }
    private string not_str( string condition ) {
        if ( auto m = std.regex.matchFirst( condition, r"^\s*(Z|NZ|CY|NCY|P|M)\s*$" ) ) { // Flag
            string flag = m[1];
            switch( flag ) {
                case "Z" : flag = "NZ"; break;
                case "NZ" : flag = "Z"; break;
                case "CY" : flag = "NCY"; break;
                case "NCY" : flag = "CY"; break;
                case "P" : flag = "M"; break;
                case "M" : flag = "P"; break;
                default : throw new Exception( "Invalid flag!" );
            }
            return flag;
        } else if ( auto m = std.regex.matchFirst( condition, r"^\s*([ABCDEHL])\s*(==|!=|<|>=|AND|NOT_AND)\s*([^\s]+)\s*$" ) ) { // compare
            string reg = m[1];
            string con = m[2];
            string val = m[3];
            switch( con ) {
                case "==" : con = "!="; break;
                case "!=" : con = "=="; break;
                case "<" : con = ">="; break;
                case ">=" : con = "<"; break;
                case "AND" : con = "NOT_AND"; break;
                case "NOT_AND" : con = "AND"; break;
                default : throw new Exception( "Invalid condition!" );
            }
            return format( " %s %s%s", reg, con, val );
        } else if ( this.condition.length == 0 ) {
            return "";
        } else {
            throw new Exception( format( "Invalid condition for not: '%s'", this.condition ) );
        }
    }

    public void write_jump( AsmWriter writer, string true_label, string comment, uint depth, string jump_cmd = "JP" ) {
        if ( auto m = std.regex.matchFirst( this.condition, r"^\s*(Z|NZ|CY|NCY|P|M)\s*$" ) ) { // Flag
            string flag = m[1];
            if ( flag == "CY" ) flag = "C";
            if ( flag == "NCY" ) flag = "NC";
            writer.add_code( format( "JP %s, %s ; %s", flag, true_label, comment ), depth );
        } else if ( auto m = std.regex.matchFirst( this.condition, r"^\s*([ABCDEHL])\s*(==|!=|<|>=|AND|NOT_AND)\s*([^\s]+)\s*$" ) ) { // Flag
            string reg = m[1];
            string con = m[2];
            string val = m[3];
            string flag = "";
            if ( auto m2 = std.regex.matchFirst( con, r"^(AND|NOT_AND)$" ) ) { // condition = AND
                if ( reg == "A" ) {
                    throw new Exception( "AND operátorhoz az A regiszter nem használható!" );
                } else {
                    writer.add_code( format( "LD A, %s ; %s", val, comment ), depth );
                    writer.add_code( format( "AND %s ; %s", reg, comment ), depth );
                    flag = ( con == "AND" ) ? "Z" : "NZ";
                }
            } else { // CP típusú feltételek
                if ( reg != "A" ) {
                    writer.add_code( format( "LD A, %s ; %s", reg, comment ), depth );
                    reg = "A";
                }
                // my $flags = { '==' => 'Z', '!=' => 'NZ', '<' => 'M', '>=' => 'P' }; # M=negatív. S=1 ; P=positive. S=0
                switch( con ) {
                    case "==" : flag = "Z"; break;
                    case "!=" : flag = "NZ"; break;
                    case "+<" : flag = "C"; break;
                    case "+>=" : flag = "NC"; break;
                    case "<" : flag = "M"; break;
                    case ">=" : flag = "P"; break;
                    default : throw new Exception( "Invalid condition" ); // M=negatív. S=1 ; P=positive. S=0
                }
                if ( auto m3 = std.regex.matchFirst( con, r"^([^\s]+)\.([^\s]+)$" ) ) { // property típusú érték
                // if ( string asmCode = class_data.get_property_value_asm( val ) ) { // Ez egy property hivatkozás
                //    val = asmCode;
                    throw new Exception( "Property a feltételben még nincs implementálva!" );
                }
                writer.add_code( format( "CP %s ; %s", val, comment ), depth );
            }
            writer.add_code( format( "%s %s, %s ; %s", jump_cmd, flag, true_label, comment ), depth );
        } else if ( this.condition.length == 0 ) {
            writer.add_code( format( "JP %s ; %s", true_label, comment ), depth );
        } else {
            throw new Exception( format( "Invalid condition: '%s'", this.condition ) );
        }
    }
}
