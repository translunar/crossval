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

  def add_source_link name
    link_to_function(name) do |page|
      page.insert_html :bottom, :sources, :partial => 'source', :object => Source.new
    end
  end
end
