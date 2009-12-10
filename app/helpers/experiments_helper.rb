module ExperimentsHelper

  def select_method form, field
    form.select field, Experiment::AVAILABLE_METHODS
  end
end
