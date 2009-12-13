class RocGroupsController < ApplicationController
  # GET /roc_groups
  # GET /roc_groups.xml
  def index
    @roc_groups = RocGroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @roc_groups }
    end
  end

  # GET /roc_groups/1
  # GET /roc_groups/1.xml
  def show
    @roc_group = RocGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @roc_group }
    end
  end

  # GET /roc_groups/new
  # GET /roc_groups/new.xml
  def new
    @roc_group = RocGroup.new
    @roc_group.items.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @roc_group }
    end
  end

  # GET /roc_groups/1/edit
  def edit
    @roc_group = RocGroup.find(params[:id])
  end

  # POST /roc_groups
  # POST /roc_groups.xml
  def create
    @roc_group = RocGroup.new(params[:roc_group])

    respond_to do |format|
      if @roc_group.save
        flash[:notice] = 'RocGroup was successfully created.'
        format.html { redirect_to(@roc_group) }
        format.xml  { render :xml => @roc_group, :status => :created, :location => @roc_group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @roc_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /roc_groups/1
  # PUT /roc_groups/1.xml
  def update
    @roc_group = RocGroup.find(params[:id])

    respond_to do |format|
      if @roc_group.update_attributes(params[:roc_group])
        flash[:notice] = 'RocGroup was successfully updated.'
        format.html { redirect_to(@roc_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @roc_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /roc_groups/1
  # DELETE /roc_groups/1.xml
  def destroy
    @roc_group = RocGroup.find(params[:id])
    @roc_group.destroy

    respond_to do |format|
      format.html { redirect_to(roc_groups_url) }
      format.xml  { head :ok }
    end
  end
end
