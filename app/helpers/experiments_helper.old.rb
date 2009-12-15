module ExperimentsHelper

  def select_method form, field
    form.select field, Experiment::AVAILABLE_METHODS
  end

  def select_distance_measure form, field
    form.select field, Experiment::AVAILABLE_DISTANCE_MEASURES
  end

  def select_validation_type form, field
    form.select field, ["row", "cell"]
  end

  def add_source_link(form_builder, experiment)
    link_to_function 'Add Source' do |page|
      form_builder.fields_for :sources, experiment.sources.build do |f|
        page.insert_html :bottom, :sources, :partial => 'sources', :locals => { :form => f }
      end
    end
  end

  # Make a link for removing a source from an experiment.
  def remove_source_link(form_builder)
    if form_builder.object.new_record?
      link_to_function("remove", "$(this).up('.source').remove();")
    else
      form_builder.hidden_field(:_delete) + link_to_function("remove", "$(this).up('.source').hide(); $(this).previous().value = '1'")
    end
  end
end
