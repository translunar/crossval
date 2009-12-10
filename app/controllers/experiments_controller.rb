class ExperimentsController < ApplicationController
  def run
    Workers::FrameWorker.async_run(:experiment_id => params[:id])
    # Inform user.
    flash[:notice] = "Running experiment #{params[:id]}"
    redirect_to matrices_url
  end

  # GET /experiments/1
  # GET /experiments/1.xml
  def show
    @experiment  = Experiment.find(params[:id])
    @flot        = Flot.new('experiment_roc_plot') do |f|
      #f.yaxis :min => 0, :max => 1
      f.points
      f.legend :position => "se"
      f.yaxis 1
      f.series @experiment.title, @experiment.roc_line
    end

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = Experiment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @experiment }
    end
  end
end