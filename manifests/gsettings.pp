/*

== Definition: gnome::gsettings

Sets a configuration key in Gnome’s GSettings registry.

Parameters:
- *$user*: the name of the system user (see user param of 'exec')
- *$schema*: the GSettings Schema to address
- *$key*: the key whose value will be changed
- *$value_type*: the type of the $value you give (defaults to 'String')
- *$value*: the value to set
- *$list_append*: wether the GSettings key is an array and the value you set
  should be appended to the existing array (defaults to 'false')
- *$get_grep*: allows to add a keyword that verifies if the modification is
  already applied. Use only if $value is an array.
  


Notes:

Never add quotes to $value.

If the GSettings key is an Array and you set $list_append to false, the $value
must be in the form of a matching GVariant serialized value (e.g. for arrays
of strings (type 'as'): "['value1', 'value2']").

If you want to add a String value to an array of strings, set $list_append to
"true", $value_type to "String" (default). $value must only contain the string
you want to append without quotes.

*/
define gnome::gsettings(
  $user,
  $schema,
  $key,
  $value,
  $value_type='String',
  $list_append=false,
  $get_grep='',
) {

  case $value_type {
    'String': { $prep_value = "'${value}'" }
    /Integer|Boolean|Array/: { $prep_value = $value }
    default: { fail "Invalid type '${value_type}'" }
  }

  $tmp_get_grep = $get_grep ? {
    '' => $prep_value,
    default => $get_grep,
  }

  $command = $list_append ? {
    # I think this commands only work when there is and X session running
    true  => "gsettings set ${schema} ${key} \"`gsettings get ${schema} ${key} | sed s/.$//`, ${prep_value}]\"",
    false => "gsettings set ${schema} ${key} \"${prep_value}\"",
  }

  # /!\ If you change a value with dconf and close it after puppet has run, it will take the dconf's value /!\
  exec {"set ${key} on user ${user} to \"${prep_value}\"":
    command     => $command,
    unless      => "gsettings get ${schema} ${key} | grep -q \"${tmp_get_grep}\"",
    user        => $user,
    environment => ['DISPLAY=:0'],
  }

}
