module ExperimentsHelper

  def remove_source_link(name, form_builder)
    form_builder.hidden_field(:_delete) + link_to_function(name, "remove_source(this)")
  end

  def add_source_link(name, source, form_builder)
    fields = escape_javascript(new_source_fields(source, form_builder))
    link_to_function(name, h("add_source(this, \"#{source}\", \"#{fields}\")"))
  end

  def new_source_fields(source, form_builder)
    form_builder.fields_for(source.pluralize.to_sym, source.camelize.constantize.new, :child_index => 'NEW_RECORD') do |f|
      render(:partial => source.underscore, :locals => { :f => f })
    end
  end

  def select_method form, field
    form.select field, Experiment::AVAILABLE_METHODS
  end

  def select_distance_measure form, field
    form.select field, Experiment::AVAILABLE_DISTANCE_MEASURES
  end

  def select_validation_type form, field
    form.select field, ["row", "cell"]
  end

end
