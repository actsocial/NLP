require "redis"
require 'soap/wsdlDriver'

class TagsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create]

  @@redis_likelihood = nil
  @@redis_prior = nil
  @@redis_tags = nil

  def index
    @@redis_prior = get_prior if @@redis_prior.nil?
    @@redis_tags = get_tag_list if @@redis_tags.nil?

    @redis_prior = @@redis_prior
    @redis_tags = @@redis_tags
    tags = Tag.joins("left join priors on priors.tag_id = tags.tag_id").joins("left join precises on precises.tag_id = tags.tag_id").select("tags.*, priors.prior, precises.precise, precises.recall, precises.true_positive, precises.false_positive, precises.true_negative, precises.false_negative, precises.test_volume, precises.updated_at")

    @tags = []
    tags.each do |tag|
      hash = {}
      hash["prior"] = tag['prior'] || ""
      hash["tag_id"] = tag.tag_id || ""
      hash["precise"] = tag.precise || ""
      hash["recall"] = tag.recall || ""
      if(tag.precise && tag.recall)
        hash["f"] = (2*tag.precise.to_f*tag.recall.to_f/(tag.precise.to_f+tag.recall.to_f)).round(4)
      end
      hash["true_positive"] = tag.true_positive.to_i || ""
      hash["false_positive"] = tag.false_positive.to_i || ""
      hash["true_negative"] = tag.true_negative.to_i || ""
      hash["false_negative"] = tag.false_negative.to_i || ""
      hash["test_volume"] = tag.test_volume || ""
      hash["updated_at"] = tag.updated_at.to_s.split(" UTC")[0] || ""
      @tags << hash
    end

    respond_to do |format|
      format.html
      format.json { render json: @tags }
    end
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
    if params[:id] && params[:id] != "index"
      @tag = Tag.find_by_id(params[:id])

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @tag }
      end
    else
      respond_to do |format|
        format.html { redirect_to tags_path } # index.html.erb
        format.json { head :no_content  }
      end
    end
  end

  # GET /tags/new
  # GET /tags/new.json
  def new
    puts params
    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find_by_id(params[:id])
  end

  # POST /tags
  # POST /tags.json
  def create
    @tag = Tag.new
    @tag.tag_id = params[:tag]
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
    @tag = Tag.find_by_id(params[:id])

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
    @tag = Tag.find_by_id(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to tags_url }
      format.json { head :no_content }
    end
  end

  def load_data
    puts params
    @@redis_likelihood = get_likelihood
    @@redis_prior = get_prior
    tag_id = params["tag"]
    main_features = Likelihood.select("tag_id, feature, likelihood").where("tag_id = '" + tag_id + "'").order("likelihood desc").limit(15)
    prior = Prior.find_by_tag_id(tag_id)

    results = {}
    results[:local] = {}
    results[:redis] = {}
    results[:features] = []
    results[:local][:prior] = prior.prior if prior
    results[:redis][:prior] = @@redis_prior[tag_id]
    results[:local][:likelihood] = {}
    results[:redis][:likelihood] = {}
    main_features.each do |mf|
      results[:features] << mf.feature
      results[:local][:likelihood][mf.feature] = mf.likelihood
      if @@redis_likelihood[tag_id]
        results[:redis][:likelihood][mf.feature] = @@redis_likelihood[tag_id][mf.feature]
      else
        results[:redis][:likelihood][mf.feature] = nil
      end
    end

    puts results
    respond_to do |format|
      format.json { render json: results }
    end

  end

  def add_to_redis
    tag_id = params[:tag]
    begin
      redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
      redis.lpush("tag_list", tag_id)
      @@redis_tags << tag_id
      respond_to do |format|
        format.json { render json: {"status" => "ok"} }
      end
    rescue Exception => e
      puts e
    end
  end

  def save_to_redis
    puts params
    @@redis_prior = get_prior if @@redis_prior.nil?
    @@redis_tags = get_tag_list if @@redis_tags.nil?
    @@redis_likelihood = get_likelihood if @@redis_likelihood.nil?

    tag_id = params["tag"]
    local_prior = params["local_prior"].to_f

    #backup_likelihood_prior(@@redis_likelihood, @@redis_prior)
    @@redis_prior[tag_id] = local_prior

    local_features = Likelihood.select("feature, likelihood").where({:tag_id => tag_id}).to_a
    local_likelihood = {}
    local_features.each do |lf|
      local_likelihood[lf.feature] = lf.likelihood.to_f
    end

    @@redis_likelihood[tag_id] = local_likelihood

    save_prior(@@redis_prior)
    save_likelihood(@@redis_likelihood)

    respond_to do |format|
      format.json { render json: {"status" => "ok"} }
    end

  end

  # redis
  def get_likelihood
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    result = {}
    redis.llen("likelihood").times.each do |i|
      result.merge!(JSON.parse(redis.lrange("likelihood", i, i)[0]))
    end
    result
  end

  def get_prior
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    ret = redis.hget("parameters", "prior")
    JSON.parse(ret)
  end

  def get_tag_list
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    redis.lrange("tag_list", 0, -1)
  end

  def save_prior(prior)
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    ret = redis.hset("parameters", "prior", prior.to_json)
  end

  def save_likelihood(likelihood)
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    redis.del("likelihood")
    likelihood.each do |k, v|
      e = {}
      e[k] = v
      redis.lpush("likelihood", e.to_json)
    end
  end

  def save_tag_list(tag_list)
    redis = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server, :port => Settings.redis_port))
    redis.del("tag_list")
    redis.lpush("tag_list",tag_list)
  end

  def backup_likelihood_prior(likelihood, prior)
    timestamp = Time.now.to_i.to_s
    bak_prior = "prior_bak" + timestamp + ".txt"
    bak_likelihood = "likelihood_bak" + timestamp + ".txt"
    File.open("G:/redis_backup_data/" + bak_prior, 'w') { |file| file.write(prior.to_json) }
    lbfile = File.open("G:/redis_backup_data/" + bak_likelihood, 'w')
    likelihood.each do |k, v|
      e = {}
      e[k] = v
      lbfile.write(e.to_json)
    end
    lbfile.close
  end

  def sync
    # from lejin
    prior = get_prior
    likelihood = get_likelihood

    # tag_list = get_tag_list
    tag_list = []
    tags = Tag.find(:all)
    tags.each do |tag|
      tag_list << tag.tag_id
    end

    # save to lejin -- tag_list from db
    save_tag_list(tag_list)

    # save to hanhuidi
    redis_hhd = Redis::Namespace.new(:parameters, :redis => Redis.new(:host => Settings.redis_server_hhd, :port => Settings.redis_port, :timeout => 3600))
    redis_hhd.hset("parameters", "prior", prior.to_json)

    redis_hhd.del("tag_list")
    redis_hhd.lpush("tag_list",tag_list)

    redis_hhd.del("likelihood")
    likelihood.each do |k, v|
      e = {}
      e[k] = v
      redis_hhd.lpush("likelihood", e.to_json)
    end

    respond_to do |format|
      format.json { render json: {"status" => "success"} }
    end
  end

  def test
    render "test"
  end

  def runtest
    puts params
    puts "=== runtest start ==="
    type = params["type"]
    if(type === "topic_id")

    elsif(type === "post_id")

    elsif(type === "content")
      body = params["content"]
    end

    @@tag_list = get_tag_list
    @@likelihood = get_likelihood
    @@prior = get_prior

    post_hashs = [{:body => body}]
    predict_tags = []
    predicted = {}
    @@soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver
    response = @@soap_client.doFeature((post_hashs||[]).collect{|p| p.nil? ? "{}" : p.to_json.to_s})
    new_features_arr = response['return'].split("|")
    new_features_arr.each_with_index do |new_features,i|
      features = []
      new_features.split(",").each do |nf|
        nf_keyword = nf.split("=")[0]
        nf_count = nf.split("=")[1].to_i
        f = "#{nf_keyword}=#{nf_count}"
        features.push nf unless nf.blank?
      end
      post_hashs[i][:features] = features[0,50] if post_hashs[i]
      post_hashs[i][:predict_version] = 1

      @@tag_list.each do |tag|
        predicted[tag] = (@@prior[tag] || 0)*1
        features.each do |feature_str|
          feature = feature_str.split("=")[0]
          count = feature_str.split("=")[1].to_i
          predicted[tag] += (@@likelihood[tag] && @@likelihood[tag][feature] || 0)*(1+Math.log(count))
        end
        predicted[tag] = 1/(1+Math.exp(0-predicted[tag]))
        if  predicted[tag]>0.55
          predict_tags << tag
        end
      end
      predict_tags.sort! {| t1,t2 | predicted[t2] <=> predicted[t1] }
      predict_tags = predict_tags[0,30]
      post_hashs[i][:predict_tags] = predict_tags||[] if post_hashs[i]
    end
    puts "=== runtest end ==="
    respond_to do |format|
      format.json { render json: {"status" => "success", "predict_tags" => predict_tags, "features" => new_features_arr, "body" => body} }
    end
  end

end
