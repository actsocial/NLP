# encoding : utf-8
require 'naivebayes'
class CalcController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create]

  # params: {:tags :array}
  def rebuild
    begin
      tags = params[:tags]
      all_categories = []
      tags.each{|tag| all_categories << [tag, "not_"+tag]}
      distinct_features = {}

      post_ids = []
      post_tags = PostTag.where({:tag_id => tags}).to_a.map(&:serializable_hash)    
      post_tags.each{|pt| post_ids << pt['post_id']}
      # post_ids = post_ids[0..300]
      post_ids.uniq!

      post_id_tag_map = {}
      post_ids.each do |post_id|
        post_id_tag_map[post_id] = post_tags.select{|pt| pt['post_id'] == post_id}
      end

      training_data = []

      # extract training data
      posts = Post.where({:id => post_ids})
      posts.each do |post|
        if (Random.rand(15)==1)
          # 3% rows are selected for testing instead of training
          post.is_test = true
          post.save
          next
        else
          post.is_test = false
          post.save
        end

        # features
        features = post.post_features.to_a.map(&:serializable_hash);nil
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

      nb = []
      all_categories.each_with_index do |categories,index|
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
  def test_rebuild
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
          fp_content[tag] << test[:body] if test[tag] == 0
        else
          tn[tag] += 1 if test[tag] == 0
          fn[tag] += 1 if test[tag] == 1
          fn_content[tag] << test[:body] if test[tag] == 1
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

      # contents = ""
      # fp_content[tag].each do |c|
      #   contents += c.gsub("\n", " ")
      # end
      # FpContent.create({:tag_id => tag, :fp_count => fp_content[tag].count, :content => contents, :test_volume => posts.count})

      # contents = ""
      # fn_content[tag].each do |c|
      #   contents += c.gsub("\n", " ")
      # end
      # FnContent.create({:tag_id => tag, :fn_count => fn_content[tag].count, :content => contents, :test_volume => posts.count})

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