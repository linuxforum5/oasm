/**
 * Értékadás
 */
import std.stdio;
import std.string;
import std.regex;
import Block:Block;
import Namespace:Namespace;
import VariableData:VariableData;
import AsmWriter:AsmWriter;
import Property:Property;
import Register8bit:Register8bit;
import Register16bit:Register16bit;
import CallClassConstructor:CallClassConstructor;
import UnconvertedAsmCode:UnconvertedAsmCode;
import DefineObject:DefineObject;
import StringConstant:StringConstant;

class Let : Block {

    public static Let it_is_this( Namespace ns, uint depth, string line, string owner_class_name ) {
        if ( auto m = std.regex.matchFirst( line, r"^([^\s]+)\s*(:?=)\s*([^\s].*)$" ) ) {
            string left_str = m[1];
            string operator = m[2];
            string right_str = m[3];
            if ( operator == "=" ) throw new Exception( format( "Need ':=' : '%s'", line ) );
            return new Let( ns, depth, line, owner_class_name, left_str, right_str );
        } else {
            return null;
        }
    }

//    private string left_str;
//    private string right_str;
    private VariableData left_var_data;
    private VariableData right_var_data;

    this( Namespace ns, uint depth, string origi_line, string owner_class_name, string left_str, string right_str ) {
        super( ns, depth, origi_line, owner_class_name );
//        this.left_str = left_str;
//        this.right_str = right_str;
        this.right_var_data = this.get_variable_data_from_value_string( this.ns, owner_class_name, right_str );

        this.left_var_data = Property.it_is_this( this.ns, owner_class_name, left_str );
        if ( this.left_var_data is null ) this.left_var_data = Register8bit.it_is_this( this.ns, owner_class_name, left_str );
        if ( this.left_var_data is null ) this.left_var_data = Register16bit.it_is_this( this.ns, owner_class_name, left_str );
        if ( this.left_var_data is null && ( cast(CallClassConstructor)this.right_var_data ) ) this.left_var_data = new DefineObject( this.ns, owner_class_name, left_str, cast(CallClassConstructor)this.right_var_data );
        if ( this.left_var_data is null ) throw new Exception( format( "Unknow left side in Let: (%s)", this.origi_line ) );

    }

    override public void convert_content( AsmWriter writer ) {
        if ( this.left_var_data is null ) {
            throw new Exception( format( "Left side of Let is null! (%s)", this.origi_line ) );
        } else {
            if ( this.right_var_data is null ) {
                throw new Exception( format( "Right side of Let is null! (%s)", this.origi_line ) );
            } else {
                this.ns.debugger.obj_info( format( "Let: %s := %s ( %s )", this.left_var_data.classinfo.name, this.right_var_data.classinfo.name, this.origi_line ) );
                this.left_var_data.load_value_from( writer, this.right_var_data, this.origi_line, this.depth );
            }
        }
    }

    public static VariableData get_variable_data_from_value_string( Namespace ns, string owner_class_name, string right_str ) {
        VariableData right_var_data = Property.it_is_this( ns, owner_class_name, right_str );
        if ( right_var_data is null ) right_var_data = Register8bit.it_is_this( ns, owner_class_name, right_str );
        if ( right_var_data is null ) right_var_data = Register16bit.it_is_this( ns, owner_class_name, right_str );
        if ( right_var_data is null ) right_var_data = StringConstant.it_is_this( ns, owner_class_name, right_str );
        if ( right_var_data is null ) right_var_data = CallClassConstructor.it_is_this( ns, owner_class_name, right_str );
        if ( right_var_data is null ) right_var_data = new UnconvertedAsmCode( ns, owner_class_name, right_str ); // Valamilyen fordítást nem igénylő assembler kód. Konstans, címke, vagy kifejezés
        return right_var_data;
    }

}
