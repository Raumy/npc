using Json;

public delegate void DelegateReadArray (Json.Node n, JsonConfigFile ncr);
public delegate void DelegateBuildObject (JsonConfigFile ncr);
public delegate void DelegateBuildArray (JsonConfigFile ncr);


public class JsonConfigFile {
  Json.Parser parser = new Json.Parser ();
  public Json.Node node = null;

  public JsonConfigFile.from_string(string s) {
    try {
      parser.load_from_data (s);
      node = parser.get_root ();
    } catch (Error e) {
      stdout.printf ("Unable to parse the string: %s\n", e.message);
    }
  }

/* READER */

  public void read_array(Json.Node? n, string name, DelegateReadArray read_array_function) {
    if (n == null) n = node;

    Json.Array array = n.get_object().get_member(name).get_array ();

    foreach (unowned Json.Node item in array.get_elements ())
      read_array_function(item, this);
  }


   public InetAddress? read_inetaddress(Json.Node? n, string name) {
    if (n == null) n = node;

    Json.Object o = n.get_object();

    if ((o != null) && (o.has_member (name)))
      return new InetAddress.from_string(o.get_string_member(name));

    return null;
  }

  public string read_string(Json.Node? n, string name) {
    if (n == null) n = node;

    return n.get_object().get_string_member(name);
  }

  public int64 read_int(Json.Node? n, string name) {
    if (n == null) n = node;

    return n.get_object().get_int_member(name);
  }

  public bool read_bool(Json.Node? n, string name) {
    if (n == null) n = node;

    return n.get_object().get_boolean_member(name);
  }


/* WRITER */

/* WRITER */
  public Json.Builder builder = null;

  public void start_builder() {
    builder = new Json.Builder();
    builder.begin_object();    
  }

  public void end_builder() {
    builder.end_object();
  }

  public void write_string(string member, string value) {
    add_member(member);
    builder.add_string_value (value);    
  }

  public void write_boolean(string member, bool value) {
  	add_member(member);
  	builder.add_boolean_value(value);
  }

  public void write_int(string member, int value) {
      builder.set_member_name(member);
      builder.add_int_value(value);
  }

  public void build_member(DelegateBuildObject build_object_function) {
    build_object_function(this);
  }

  public void add_member(string member) {
    builder.set_member_name(member);    
  }

  public void build_array(string member, DelegateBuildArray build_array_function) {
    add_member(member);
    builder.begin_array();    
    build_array_function(this);
    builder.end_array();    
  }

  public string generate_string_data() {
	Json.Generator generator = new Json.Generator ();
	generator.set_pretty (true);
	Json.Node root = builder.get_root ();
	generator.set_root (root);

	return generator.to_data (null);  	
  }
}

