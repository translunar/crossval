class RocsController < ApplicationController
  # GET /Rocs
  # GET /Rocs.xml
  def index
    @Rocs = Roc.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @Rocs }
    end
  end

  # GET /Rocs/1
  # GET /Rocs/1.xml
  def show
    @Roc = Roc.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @Roc }
    end
  end

  # GET /Rocs/new
  # GET /Rocs/new.xml
  def new
    @Roc = Roc.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @Roc }
    end
  end

  # GET /Rocs/1/edit
  def edit
    @Roc = Roc.find(params[:id])
  end

  # POST /Rocs
  # POST /Rocs.xml
  def create
    @Roc = Roc.new(params[:Roc])

    respond_to do |format|
      if @Roc.save
        flash[:notice] = 'Roc was successfully created.'
        format.html { redirect_to(@Roc) }
        format.xml  { render :xml => @Roc, :status => :created, :location => @Roc }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @Roc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /Rocs/1
  # PUT /Rocs/1.xml
  def update
    @Roc = Roc.find(params[:id])

    respond_to do |format|
      if @Roc.update_attributes(params[:Roc])
        flash[:notice] = 'Roc was successfully updated.'
        format.html { redirect_to(@Roc) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @Roc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /Rocs/1
  # DELETE /Rocs/1.xml
  def destroy
    @Roc = Roc.find(params[:id])
    @Roc.destroy

    respond_to do |format|
      format.html { redirect_to(Rocs_url) }
      format.xml  { head :ok }
    end
  end
end
