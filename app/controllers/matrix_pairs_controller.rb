class MatrixPairsController < ApplicationController
  # GET /matrix_pairs
  # GET /matrix_pairs.xml
  def index
    @matrix_pairs = MatrixPair.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @matrix_pairs }
    end
  end

  # GET /matrix_pairs/1
  # GET /matrix_pairs/1.xml
  def show
    @matrix_pair = MatrixPair.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @matrix_pair }
    end
  end

  # GET /matrix_pairs/new
  # GET /matrix_pairs/new.xml
  def new
    @matrix_pair = MatrixPair.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @matrix_pair }
    end
  end

  # GET /matrix_pairs/1/edit
  def edit
    @matrix_pair = MatrixPair.find(params[:id])
  end

  # POST /matrix_pairs
  # POST /matrix_pairs.xml
  def create
    @matrix_pair = MatrixPair.new(params[:matrix_pair])

    respond_to do |format|
      if @matrix_pair.save
        flash[:notice] = 'MatrixPair was successfully created.'
        format.html { redirect_to(@matrix_pair) }
        format.xml  { render :xml => @matrix_pair, :status => :created, :location => @matrix_pair }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @matrix_pair.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /matrix_pairs/1
  # PUT /matrix_pairs/1.xml
  def update
    @matrix_pair = MatrixPair.find(params[:id])

    respond_to do |format|
      if @matrix_pair.update_attributes(params[:matrix_pair])
        flash[:notice] = 'MatrixPair was successfully updated.'
        format.html { redirect_to(@matrix_pair) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @matrix_pair.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /matrix_pairs/1
  # DELETE /matrix_pairs/1.xml
  def destroy
    @matrix_pair = MatrixPair.find(params[:id])
    @matrix_pair.destroy

    respond_to do |format|
      format.html { redirect_to(matrix_pairs_url) }
      format.xml  { head :ok }
    end
  end
end
