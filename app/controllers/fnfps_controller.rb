class FnfpsController < ApplicationController

  # GET /fnfps
  # GET /fnfps.json
  def index
    flag = params["f"]
    tag_id = params["t"]
    #fnfps = Fnfp.find_by_sql ["select * from fnfps join posts where fnfps.flag = ? and fnfps.tag_id = ?",flag,tag_id]
    fnfps = Fnfp.find(:all,:conditions=>["flag = ? and tag_id = ?",flag,tag_id])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @fnfps }
    end
  end

  # GET /fnfps/1
  # GET /fnfps/1.json
  def show
    @fnfp = Fnfp.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @fnfp }
    end
  end

  # GET /fnfps/new
  # GET /fnfps/new.json
  def new
    @fnfp = Fnfp.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @fnfp }
    end
  end

  # GET /fnfps/1/edit
  def edit
    @fnfp = Fnfp.find(params[:id])
  end

  # POST /fnfps
  # POST /fnfps.json
  def create
    @fnfp = Fnfp.new(params[:fnfp])

    respond_to do |format|
      if @fnfp.save
        format.html { redirect_to @fnfp, notice: 'Fnfp was successfully created.' }
        format.json { render json: @fnfp, status: :created, location: @fnfp }
      else
        format.html { render action: "new" }
        format.json { render json: @fnfp.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /fnfps/1
  # PUT /fnfps/1.json
  def update
    @fnfp = Fnfp.find(params[:id])

    respond_to do |format|
      if @fnfp.update_attributes(params[:fnfp])
        format.html { redirect_to @fnfp, notice: 'Fnfp was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @fnfp.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fnfps/1
  # DELETE /fnfps/1.json
  def destroy
    @fnfp = Fnfp.find(params[:id])
    @fnfp.destroy

    respond_to do |format|
      format.html { redirect_to fnfps_url }
      format.json { head :no_content }
    end
  end
end
