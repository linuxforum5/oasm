/**
 * Nem módosított sor
 */
import std.stdio;
import std.string;
import std.regex;
import Block:Block;
import Namespace:Namespace;
import AsmWriter:AsmWriter;

class UnconvertedAsmLine : Block {

    this( Namespace ns, uint depth, string origi_line, string owner_class_name ) {
        super( ns, depth, origi_line, owner_class_name );
        this.validate_asm_line( origi_line );
    }

    override public void convert_content( AsmWriter writer ) {
        writer.add_code( this.origi_line, this.depth );
    }

    private void validate_asm_line( string line ) {
        if ( auto m = std.regex.matchFirst( line, r"^[^\s\:]+\:\s*(.*)$" ) ) { // Címke van a sor elején. Ezt vágjuk le
            line = m[1];
        }
        if ( auto m = std.regex.matchFirst( line, r"^(NOP|NEG|SCF|CCF|RLA|RRA|CPL|RET|RRCA|EXX|HALT|LDIR|DAA|RLD|DI|EI)$" ) ) { // Paraméter nélkülis asm kód
        } else if ( auto m = std.regex.matchFirst( line, r"^(PUSH|POP|OR|AND|INC|DEC|CALL|JP|JR|SUB|SRL|ORG|CP|XOR|SRA|SLA|RET|RL|RLC|DJNZ)\s+[^\s]+$" ) ) { // 1 paraméteres asm kód
        } else if ( auto m = std.regex.matchFirst( line, r"^(LD|EX|ADD|ADC|JR|JP|OUT|IN|BIT|RES|SBC|SET|EXX)\s+.+\s*,\s*[^\s].*$" ) ) { // 2 paraméteres asm kód
        } else if ( auto m = std.regex.matchFirst( line, r"^include '.*'$" ) ) { // ok
        } else if ( auto m = std.regex.matchFirst( line, r"^([^\s:]+:|)\s*((DB|DW|DS|EQU|JR)\s+.*|)$" ) ) { // Címkézett sor
        } else if ( auto m = std.regex.matchFirst( line, r"^(DB|DW|DS)\s+.*$" ) ) { // Adatok
        } else {
            throw new Exception( format( "Invalid asm line: '%s'", line ) );
        }
    }

}
