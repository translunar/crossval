# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def select_matrix form, field
    form.collection_select field, Matrix.all, :id, :title
  end

  def select_experiment form, field
    form.collection_select field, Experiment.all, :id, :argument_string
  end
end
