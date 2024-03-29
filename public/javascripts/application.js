// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function add_source(element, source_name, new_source) {
  $('experiment_sources').insert({
    bottom: new_source.replace(/NEW_RECORD/g, new Date().getTime())
  });
}

function add_nested(element, nested_type, new_nested) {
  $(nested_type).insert({
    bottom: new_nested.replace(/NEW_RECORD/g, new Date().getTime())
  });
}

function remove_source(element) {
  var hidden_field = $(element).previous("input[type=hidden]");
  if (hidden_field) {
    hidden_field.value = '1';
  }
  $(element).up(".source").hide();
}

function remove_roc_group_item(element) {
  var hidden_field = $(element).previous("input[type=hidden]");
  if (hidden_field) {
    hidden_field.value = '1';
  }
  $(element).up(".roc_group_item").hide();
}

