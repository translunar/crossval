# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def select_matrix form, field
    form.collection_select field, Matrix.all, :id, :title
  end
end
