/**
 * Egy értékadás bal oldalán álló önálló azonosító. Ez egy globális objektum neve, amit a jobboldalon álló new class() kifejezés fog definiálni.
 */
import std.stdio;
import std.string;
import std.regex;
import Namespace:Namespace;
import VariableData:VariableData;
import ClassData:ClassData;
import CallClassConstructor:CallClassConstructor;
import AsmWriter:AsmWriter;
import ObjectData:ObjectData;
import Call:Call;

class DefineObject : VariableData {

    private string object_name;
    private static uint counter = 0;

    this( Namespace ns, string owner_class_name, string object_name, CallClassConstructor right_var_data ) {
        super( ns, owner_class_name );
        this.object_name = object_name;
        ClassData class_data = right_var_data.get_class_data();
        if ( class_data is null ) throw new Exception( format( "Új objektum null osztállyal? Object='%s', Owner='%s'", object_name, owner_class_name ) );
//        if ( class_data.classinfo.name == "ClassData.ClassData" ) throw new Exception( format( "Új objektum valamilyen Property-be kellene tartoznia! Object='%s', Owner='%s'", object_name, owner_class_name ) );
        if ( ns.is_object( object_name ) ) {
            ObjectData object_data = ns.get_object_data( object_name );
            object_data.set_class_data( class_data ); // Ha null, akkor beállítja, ha már meg van adva, akkor ellenőrzi, hogy azonos-e
        } else {
            ns.add_object( object_name, new ObjectData( object_name, class_data ) ); // Amíg nem ismerjük az objektum osztályát, addig null
        }
/*
        ObjectData object_data = ns.get_object_data( object_name );
        if ( class_data.multi_instance() ) { // Ennek az osztálynak lehet több objektuma is, így memóriát kell allokálni az egyes példányok számára
            string object_data_label = class_data.get_new_object_data_label( object_name );
            object_data.set_data_label( object_data_label );
        } else {
            object_data.set_data_label( "undefinde data label with single instance class" );
        }
*/
    }

    // For create new object:
    override public void load_value_from( AsmWriter writer, VariableData right_var_data, string comment, uint depth ) {
        if ( CallClassConstructor constructor = cast(CallClassConstructor)right_var_data ) { // A jobboldalon egy new áll
            ClassData constructor_class_data = constructor.get_class_data();
            if ( constructor_class_data.multi_instance() ) { // Ennek az osztálynak lehet több objektuma is, így memóriát kell allokálni az egyes példányok számára
                DefineObject.generate_new_indexed_object_code( writer, this.ns, this.object_name, constructor, this.owner_class_name, comment, depth );
/*
                ObjectData object_data = this.ns.get_object_data( this.object_name ); // left_str ebben az esetben az objektum neve lehet csak
                string obj_data_label = object_data.get_data_label();
                class_data.gen_object_selector_code( writer, obj_data_label, comment, depth );
                writer.add_data( obj_data_label, format( "DS %d,0 ; %s", class_data.get_class_data_size(), comment ) ); // Allocate memory in data segment: DS size,0
                Call.write_content( this.ns, this.owner_class_name, writer, class_data, "constructor", constructor.get_constructor_param_str(), "", comment, depth );
                // Ez itt ugyanaz a kód, mint a Register16bit-nél!!!!!!
*/
            } else {
                Call.write_content( this.ns, this.owner_class_name, writer, constructor_class_data, "constructor", constructor.get_constructor_param_str(), "", comment, depth );
            }
        } else {
            throw new Exception( "Objektum létrehozás jobboldalán csak new class() kifejezés állhat!" );
        }
//        ObjectData object_data = this.ns.get_object_data( this.object_name ); // Ennek egy memberváltozóját állítjuk
//        object_data.load_property_value_from( writer, this.property_name, right_var_data, comment );
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// Amennyiben egy értékadás jobb oldalán egy new() kifejezés található, ez a kód konvertálja azt
    /// Baloldalon állhat objektum, regiszter, property, vagy lehet a kifejezés egy paraméter - ami majd egy regiszterbe töltődik
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static ObjectData generate_new_indexed_object_code( AsmWriter writer, Namespace ns, string object_name, CallClassConstructor constructor, string owner_class_name, string comment, uint depth ) {
        ClassData class_data = constructor.get_class_data();
        if ( class_data.multi_instance() ) { // Ennek az osztálynak lehet több objektuma is, így memóriát kell allokálni az egyes példányok számára
            ObjectData obj_data = DefineObject.get_object_data( ns, object_name, class_data );
            string obj_data_label = obj_data.get_data_label();
            class_data.gen_object_selector_code( writer, obj_data_label, comment, depth );
            writer.add_data( obj_data_label, format( "DS %d,0 ; %s", class_data.get_class_data_size(), comment ), class_data.get_class_data_size() ); // Allocate memory in data segment: DS size,02
            Call.write_content( ns, owner_class_name, writer, class_data, "constructor", constructor.get_constructor_param_str(), "", comment, depth );
            // Ez itt ugyanaz a kód, mint a Register16bit-nél!!!!!!
            return obj_data;
        } else {
            throw new Exception( "Csak indexed objektumnak generálható new exptression értékként" );
        }
    }

    private static ObjectData get_object_data( Namespace ns, string object_name, ClassData class_data ) {
        if ( object_name.length > 0 ) {
            return ns.get_object_data( object_name ); // left_str ebben az esetben az objektum neve lehet csak
        } else {
            return new ObjectData( "", class_data );
        }
    }

}
