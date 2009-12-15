# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def select_matrix form, field
    form.collection_select field, Matrix.all, :id, :title
  end

  def select_experiment form, field
    form.collection_select field, Experiment.all, :id, :argument_string
  end

  def remove_nested_link(name, nested_type, form_builder)
    form_builder.hidden_field(:_delete) + link_to_function(name, "remove_#{nested_type}(this)")
  end

  def add_nested_link(name, nested, nested_type, form_builder)
    fields = escape_javascript(new_nested_fields(nested_type, form_builder))
    link_to_function(name, h("add_nested(this, \"#{nested}\", \"#{fields}\")"))
  end

  def new_nested_fields(source, form_builder)
    form_builder.fields_for(source.pluralize.to_sym, source.camelize.constantize.new, :child_index => 'NEW_RECORD') do |f|
      render(:partial => source.underscore, :locals => { :f => f })
    end
  end


end
