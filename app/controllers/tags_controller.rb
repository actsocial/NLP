require "redis"
class TagsController < ApplicationController
  # GET /tags
  # GET /tags.json
  @@redis_likelihood = nil
  @@redis_prior = nil
  @@redis_tags = nil
  def index
    @@redis_likelihood = get_likelihood if @@redis_likelihood.nil?
    @@redis_prior = get_prior if @@redis_prior.nil?
    @@redis_tags = get_tag_list if @@redis_tags.nil?
    @tags = Prior.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tags }
    end
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
    @tag = Tag.find_by_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.json
  def new
    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find(params[:id])
  end

  # POST /tags
  # POST /tags.json
  def create
    @tag = Tag.new
    @tag.id = params[:tag]

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render json: @tag, status: :created, location: @tag }
      else
        format.html { render action: "new" }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.json
  def update
    @tag = Tag.find(params[:id])

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        format.html { redirect_to @tag, notice: 'Tag was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to tags_url }
      format.json { head :no_content }
    end
  end

  def load_data
    tag_id = params[:tag]
    begin
      table_name = tag_id.gsub('.','_')
      main_features = ActiveRecord::Base.connection.execute("select `tag_id`, `feature`, `likelihood` from LIKELIHOOD_"+table_name+" order by `freq1` desc limit 5")
      results = {}
      results[:local] = {}
      results[:redis] = {}
      results[:features] = []
      results[:local][:prior] = Prior.find_by_tag_id(tag_id).prior
      results[:redis][:prior] = @@redis_prior[tag_id]
      results[:local][:likelihood] = {}
      results[:redis][:likelihood] = {}
      main_features.each do |mf|
        results[:features] << mf[1]
        results[:local][:likelihood][mf[1]] = mf[2]
        results[:redis][:likelihood][mf[1]] = @@redis_likelihood[tag_id][mf[1]]
      end
      puts @@redis_prior

      respond_to do |format|
        format.json{render json: results}
      end
    rescue Exception => e
      puts e
    end
  end

  def save_to_redis
    tag_id = params[:tag]
    local_prior = params[:local_prior]
    begin
      backup_likelihood_prior(@@redis_likelihood, @@redis_prior)
      @@redis_prior[tag_id] = local_prior
      table_name = tag_id.gsub('.','_')
      local_features = ActiveRecord::Base.connection.execute("select `feature`, `likelihood` from LIKELIHOOD_"+table_name).to_a
      local_likelihood = {}
      local_features.each do |lf|
        local_likelihood[lf[0]] = lf[1]
      end
      @@redis_likelihood[tag_id] = local_likelihood
      
      save_prior(@@redis_prior)
      save_likelihood(@@redis_likelihood)
      respond_to do |format|
        format.json {render json:{"status"=>"ok"}}
      end
    rescue Exception => e
      puts e
    end
  end

  def get_likelihood
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    result = {}
    redis.llen("likelihood").times.each do |i|
      result.merge!(JSON.parse(redis.lrange("likelihood",i,i)[0]))
    end
    result
  end
  
  def get_prior
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    ret = redis.hget("parameters","prior")
    JSON.parse(ret)
  end

  def get_tag_list
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    redis.lrange("tag_list",0,-1)
  end

  def save_prior(prior)
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    ret = redis.hset("parameters","prior",prior.to_json)
  end
  
  def save_likelihood(likelihood)
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    redis.del("likelihood")
    likelihood.each do |k,v|
      e = {}
      e[k] = v
      redis.lpush("likelihood",e.to_json)
    end
  end

  def backup_likelihood_prior(likelihood, prior)
    timestamp = Time.now.to_i.to_s
    bak_prior = "prior_bak" + timestamp + ".txt"
    bak_likelihood = "likelihood_bak" + timestamp + ".txt"
    File.open("G:/redis_backup_data/" + bak_prior, 'w') { |file| file.write(prior.to_json) }
    lbfile = File.open("G:/redis_backup_data/" + bak_likelihood, 'w')
    likelihood.each do |k,v|
      e = {}
      e[k] = v
      lbfile.write(e.to_json)
    end
    lbfile.close
  end
end
