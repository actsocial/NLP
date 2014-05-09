class TopicDatesController < ApplicationController
  # GET /topic_dates
  # GET /topic_dates.json
  def index
    @topic_dates = TopicDate.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topic_dates }
    end
  end

  # GET /topic_dates/1
  # GET /topic_dates/1.json
  def show
    @topic_date = TopicDate.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @topic_date }
    end
  end

  # GET /topic_dates/new
  # GET /topic_dates/new.json
  def new
    @topic_date = TopicDate.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @topic_date }
    end
  end

  # GET /topic_dates/1/edit
  def edit
    @topic_date = TopicDate.find(params[:id])
  end

  # POST /topic_dates
  # POST /topic_dates.json
  def create
    @topic_date = TopicDate.new(params[:topic_date])

    respond_to do |format|
      if @topic_date.save
        format.html { redirect_to @topic_date, notice: 'Topic date was successfully created.' }
        format.json { render json: @topic_date, status: :created, location: @topic_date }
      else
        format.html { render action: "new" }
        format.json { render json: @topic_date.errors, status: :unprocessable_entity }
      end
    end
  end

  def get_daily_topics
    topics = TopicDate.find_by_sql("SELECT date, GROUP_CONCAT(topic SEPARATOR ', ') as topic_str FROM topic_dates GROUP BY date")
    puts topics
    result = {}
    result["values"] = []
    topics.each_with_index do |topic,index|
      result["values"][index] = {x: (DateTime.parse(topic.date.to_s)).to_i * 1000, y: 3}
    end
    res = [{values: result["values"],
            key: 'topic str',
            color: '#ff7f0e'}]
    respond_to do |format|
      format.json { render json: res.to_json }
    end
  end

  # PUT /topic_dates/1
  # PUT /topic_dates/1.json
  def update
    @topic_date = TopicDate.find(params[:id])

    respond_to do |format|
      if @topic_date.update_attributes(params[:topic_date])
        format.html { redirect_to @topic_date, notice: 'Topic date was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @topic_date.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /topic_dates/1
  # DELETE /topic_dates/1.json
  def destroy
    @topic_date = TopicDate.find(params[:id])
    @topic_date.destroy

    respond_to do |format|
      format.html { redirect_to topic_dates_url }
      format.json { head :no_content }
    end
  end
end
