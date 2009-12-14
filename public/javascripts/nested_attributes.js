function add_source(element, source_name, new_source) {
  $('experiment_sources').insert({
    bottom: new_source.replace(/NEW_RECORD/g, new Date().getTime())
  });
}

function remove_source(element) {
  var hidden_field = $(element).previous("input[type=hidden]");
  if (hidden_field) {
    hidden_field.value = '1';
  }
  $(element).up(".source").hide();
}
