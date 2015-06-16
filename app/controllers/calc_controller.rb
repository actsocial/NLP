# encoding : utf-8
require 'naivebayes'
class CalcController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create]

  def rebuild # params: {:tags :array}
    puts params
    begin
      tags = params[:tags]
      all_categories = []
      tags.each{|tag| all_categories << [tag, "not_"+tag]}
      # all_categories = [["baby", "not_baby"]]

      pp "loading post ids"
      distinct_features = {}
      post_ids = []
      post_tags = PostTag.where({:tag_id => tags}).to_a.map(&:serializable_hash) # limit()  post_ids = post_ids[0..300]
      post_tags.each{|pt| post_ids << pt['post_id']}
      post_ids.uniq!

      post_id_tag_map = {}
      post_ids.each do |post_id|
        post_id_tag_map[post_id] = post_tags.select{|pt| pt['post_id'] == post_id}
      end
      # post_id_tag_map = {1=>[{"created_at"=>Thu, 20 Mar 2014 11:21:46 UTC +00:00, "id"=>4, "post_id"=>1, "tag_id"=>"baby", "updated_at"=>Thu, 20 Mar 2014 11:21:46 UTC +00:00, "value"=>0}]}

      # extract training data
      training_data = []

      pp "loading posts"
      posts = Post.where({:id => post_ids})
      pp posts.count.to_s+" posts are loaded"
      i = 0
      posts.each do |post|
        i += 1
        if (Random.rand(30)==1) # 3% rows are selected for testing instead of training
          pp i
          post.is_test = true
          post.save
          next
        else
          # post.is_test = false
          # post.save
        end

        features = post.post_features.to_a.map(&:serializable_hash)
        #features = [{"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"分享", "id"=>1, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"欧洲", "id"=>2, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}]
        if features.blank?
          next
        end

        category = []
        all_categories.each do |cat|
          exist_tag = post_id_tag_map[post.id].select{|pt| pt['tag_id'] == cat[0]}.first
          if !exist_tag.blank?
            if exist_tag['value'] == 1
              category << cat[0]
            elsif exist_tag['value'] == 0
              category << cat[1]
            else
              next
            end
          end
        end

        category.each do |c|
          if distinct_features[c].nil?
            distinct_features[c] = {}  
          end
          features.each do |feature|
            f = feature["feature"]
            if distinct_features[c][f].nil?
              distinct_features[c][f] = 1
            else
              distinct_features[c][f] += feature["occurrence"]
            end
          end
        end
        training_data << {:features => features, :category => category}
      end
      #training_data = [{:features=>[{"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"分享", "id"=>1, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"欧洲", "id"=>2, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"最后", "id"=>3, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"斯内德", "id"=>4, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"HTTP", "id"=>5, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"再见", "id"=>6, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"球星", "id"=>7, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"黑", "id"=>8, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"生涯", "id"=>9, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"视频", "id"=>10, "occurrence"=>2, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"新浪", "id"=>11, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}, {"created_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00, "feature"=>"一个", "id"=>12, "occurrence"=>1, "post_id"=>1, "updated_at"=>Fri, 21 Mar 2014 01:29:49 UTC +00:00}], :category=>["not_baby"]}]
      pp "start calculation "
      nb = []
      all_categories.each_with_index do |categories,index| # ??????????????
        training_data.each_with_index do |data, j|
          if data[:category].include?(categories[0]) || data[:category].include?(categories[1])
            nb[index] ||= NaiveBayes.new(categories,
                                  {categories[0]=>distinct_features[categories[0]].nil? ? 0 : distinct_features[categories[0]].size,
                                   categories[1]=>distinct_features[categories[1]].nil? ? 0 : distinct_features[categories[1]].size})
            c = data[:category].include?(categories[0]) ? categories[0] : categories[1]
            nb[index].train(c, data[:features])
          end
        end
      end

      priors = {}
      all_categories.each_with_index do |category, index|
        if nb[index]
          a = nb[index].category_probability(category[0])
          b = nb[index].get_likelihood

          prior = Prior.find_by_tag_id(category[0])
          if prior
            pp prior
            prior.prior = a.to_f.round(5)
            prior.save
          else
            Prior.create({:tag_id => category[0], :prior => a.to_f.round(5)})
          end
          priors[category[0]] = a.to_f.round(5)
          Likelihood.delete_all(["tag_id = ?", category[0]])
          b.each do |feature, likelihood|
            Likelihood.create({:tag_id => category[0], :feature => feature.to_s, :likelihood => likelihood.to_f.round(5)})
          end
        end
      end

      respond_to do |format|
        format.json { render json: {"status" => "ok", "priors" => priors} }
      end
    rescue Exception => e
      pp e
      respond_to do |format|
        format.json { render json: {"status" => "error"} }
      end
    end
  end

  # params => {tags:array}
  def test_rebuild # Batch Test
    tags = params[:tags]

    # get prior from database
    prior = {}
    Prior.where({:tag_id => tags}).each do |p|
      prior[p.tag_id] = p.prior if !prior[p.tag_id]
    end

    # get likelihood from database
    likelihood = {}
    Likelihood.where({:tag_id => tags}).to_a.map(&:serializable_hash).each do |lh|
      likelihood[lh['tag_id']] = {} if !likelihood[lh['tag_id']]
      likelihood[lh['tag_id']][lh['feature']] = lh['likelihood']
    end

    all_categories = []
    tags.each{|tag| all_categories << [tag, "not_"+tag]}
    distinct_features = {}

    post_ids = []
    # post_tags = PostTag.where({:tag_id => tags}).to_a.map(&:serializable_hash);nil
    post_tags = PostTag.joins("left join posts on post_tags.post_id = posts.id").where({post_tags:{:tag_id => tags}, posts:{:is_test => true}}).to_a.map(&:serializable_hash);nil
    post_tags.each{|pt| post_ids << pt['post_id']}
    post_ids.uniq!

    post_id_tag_map = {}
    post_ids.each do |post_id|
      post_id_tag_map[post_id] = [] if !post_id_tag_map[post_id]
      post_id_tag_map[post_id] = post_tags.select{|pt| pt['post_id'] == post_id}
    end

    results = []
    tp = {}
    fp = {}
    tn = {}
    fn = {}
    fp_content = {}
    fn_content = {}
    tags.each do |tag|
      tp[tag] = 0
      fp[tag] = 0
      tn[tag] = 0
      fn[tag] = 0
      fp_content[tag] = []     
      fn_content[tag] = []
    end

    posts = Post.where({:id => post_ids, :is_test => true})
    posts.each do |post|
      test = {}
      test[:body] = post.content
      all_categories.each do |category|
        exist_tag = post_id_tag_map[post.id].select{|pt| pt['tag_id'] == category[0]}.first
        if !exist_tag.blank?
          test[category[0]] = exist_tag['value']
        end
      end

      predict_tags = []
      predicted = {}

      features = post.post_features.to_a.map(&:serializable_hash)
      
      tags.each do |tag|
        predicted[tag] = (prior[tag] || 0)*1 #weight of prior reduced for lack of training data, by ice
        features.each do |feature_ele|
          feature = feature_ele['feature']
          count = feature_ele['occurrence']
          predicted[tag] += (likelihood[tag][feature]|| 0)*(1+Math.log(count))
        end
        predicted[tag] = 1/(1+Math.exp(0-predicted[tag]))
        if predicted[tag] > 0.51
          tp[tag] += 1 if test[tag] == 1
          fp[tag] += 1 if test[tag] == 0
          fp_content[tag] << post.id if test[tag] == 0
        else
          tn[tag] += 1 if test[tag] == 0
          fn[tag] += 1 if test[tag] == 1
          fn_content[tag] << post.id if test[tag] == 1
        end
      end
    end

    x = 0
    y = 0
    m = 0
    n = 0
    #save tag precise and recall
    # FpContent.delete_all({:tag_id => tags})
    # FnContent.delete_all({:tag_id => tags})

    # delete fnfp if same
    Fnfp.delete_all({:tag_id => tags})

    return_precise = {}
    tags.each do |tag|
      precise = Precise.find_by_tag_id(tag)
      if (tp[tag]+fp[tag]+fn[tag]>10)
        temp_precise = ((tp[tag].to_f/(tp[tag]+fp[tag]))*100).round(1)
        temp_recall = ((tp[tag].to_f/(tp[tag]+fn[tag]))*100).round(1)
      else
        temp_precise = 0
        temp_recall = 0
      end
      if precise
        precise.true_positive = tp[tag]
        precise.false_positive = fp[tag]
        precise.true_negative = tn[tag]
        precise.false_negative = fn[tag]
        precise.test_volume = posts.count
        precise.precise = temp_precise
        precise.recall = temp_recall
        precise.save
      else
        Precise.create({
          :tag_id => tag,
          :true_positive => tp[tag],
          :false_positive => fp[tag],
          :true_negative => tn[tag],
          :false_negative => fn[tag],
          :test_volume => posts.count,
          :precise => temp_precise,
          :recall => temp_recall
        })
      end

      return_precise[tag] = {
        'true_positive' => tp[tag],
        'false_positive' => fp[tag],
        'true_negative' => tn[tag],
        'false_negative' => fn[tag],
        'test_volume' => posts.count,
        'precise' => temp_precise,
        'recall' => temp_recall,
        'updated_at' => Time.now
      }

      # save fn fp to fnfps
      fp_content[tag].each do |c|
        Fnfp.create({:tag_id => tag, :flag => "fp", :post_id => c})
      end

      fn_content[tag].each do |c|
        Fnfp.create({:tag_id => tag, :flag => "fn", :post_id => c})
      end

      x += tp[tag].to_f
      y += tp[tag]+fp[tag]
      m += tp[tag].to_f
      n += tp[tag]+fn[tag]
    end

    overall_precise = (x/y*100).to_f.round(1).to_s + "%"
    overall_recall = (m/n*100).to_f.round(1).to_s + "%"

    respond_to do |format|
      format.json { render json: {"status" => "ok", "overall_recall" => overall_recall, "overall_precise" => overall_precise, "precise" => return_precise}}
    end
  end
end