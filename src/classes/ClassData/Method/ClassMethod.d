import std.string;

class ClassMethod {

    protected string owner_class_name; // Egy címke, ami vagy egy memóriacímet azonosít, vagy egy konstanst
    protected string method_name;
    protected string param_str;
    private bool multi_instance_class;

    this( string owner_class_name, string method_name, string param_str, bool multi_instance_class ) {
        this.owner_class_name = owner_class_name;
        this.method_name = method_name;
        this.param_str = param_str;
        this.multi_instance_class = multi_instance_class;
    }

    public string get_method_name() { return this.method_name; }
    public string get_method_label() { return format( "%s_Class_%s_Method_%s_Code", ( this.multi_instance_class? "Multi" : "Direct" ), this.owner_class_name, this.method_name ); }

    public string get_param_str() { return this.param_str; }

}
