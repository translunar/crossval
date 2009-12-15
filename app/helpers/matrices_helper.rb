module MatricesHelper

  # The link to run experiments for a matrix.
  def run_link(matrix_or_experiment)
    link_to('Run', {
        :controller => matrix_or_experiment.class.table_name,
        :action     => "run",
        :id         => matrix_or_experiment.id },
      :confirm => 'Are you sure?')
  end

  def view_matrix_path(matrix)
    url_for( :controller => "matrices", :action => "view", :id => matrix.id )
  end

  def source_matrices(exp)
    l = exp.source_matrices.collect { |sm| link_to(sm.title, sm) }.join("\n")
    if l.nil? || l.size == 0
      "None"
    else
      l
    end
  end

  def fractional_density(matrix)
    "<sup>#{matrix.density}</sup><i>/</i><sub>#{matrix.number_of_rows}</sub>"
  end

  # Display the link to run experiments for a matrix iff it's possible to run for
  # that matrix.
  def run_link_if_appropriate(matrix)
    # Only allow running of parent if its children have been run.
    if matrix.has_experiments_to_run?
      run_link(matrix)
    else
      nil
    end
  end

  def cardinality(matrix)
    if matrix.parent_id.nil?
      nil
    else
      "#{matrix.cardinality+1} / #{matrix.parent.divisions}"
    end
  end

  def link_to_experiment_if_appropriate(experiment)
    return nil if experiment.total_auc.nil?

    link_to experiment.total_auc, experiment
  end
end
