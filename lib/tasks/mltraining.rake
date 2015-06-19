# encoding : utf-8
require 'rubygems'
require 'rake'
require "#{Rails.root}/app/models/naivebayes"
require 'soap/wsdlDriver'
require 'nokogiri'
require "#{Rails.root}/app/models/settings"
# require "crawler_redis"
# require "#{Rails.root}/app/models/complementaryNaiveBayes"

namespace :training do
  # include CrawlerRedis
  desc "execute naive bayes training"

  task :import_posts, :environment do |t, args|
    new_posts = []
    tag_list = []
    soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver
    doc = Nokogiri::XML(File.open("lib/13495(all).xml"))

    doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
      # read taglist
      if (i==0 && row.css("Data").count>1)
        row.css("Data")[1..-1].each do |tag|
          tag_list << tag.text
        end
        next
      end

      body = row.css("Data")[0].text
      p = Post.new
      p.content = body
      p.save
      new_posts << p

      post_tags = []
      tag_list.each_with_index do |t, index|
        data = row.css("Data")[index+1]
        if data.nil?
          next
        end
        value = data.text
        if value == "1" || value=="0"
          pt = PostTag.new
          pt.post_id = p.id
          pt.tag_id = t
          pt.value = value.to_i
          post_tags << pt
        else
          next
        end
      end
      PostTag.import post_tags
    end
    # 为新的posts存feature
    if new_posts.count > 0
      new_posts.each do |post|
        document = {:body => post.content}
        response = soap_client.doFeature([document].collect { |p| p.nil? ? "{}" : p.to_json.to_s })
        if response['return'].blank?
          next
        end
        pfs = []
        features = response['return'].split("|")[0].split(",")
        features.each do |feature|
          f = feature.split("=")[0]
          occurrence = feature.split("=")[1]
          #存posts_features， post_id, f, occurance（数字！！！）
          pf = Post_Feature.new
          pf.post_id = post.id
          pf.feature = f
          pf.occurrence = occurrence.to_i
          pfs << pf
        end
        Post_Feature.import pfs
      end
    end
  end

  task :run, :environment do |t, args|
    r = Redis.new(:host => Settings.redis_server, :port => Settings.redis_port)
    redis = Redis::Namespace.new(:parameters, :redis => r)

    tag_list = ['positive','negative']
    all_categories = []
    tag_list.each{|tag| all_categories << [tag, "not_"+tag]}

    distinct_features = {}

    # extract training data
    training_data = []
    @@soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver
    doc = Nokogiri::XML(File.open("lib/20150612(positive+negative).xml"))

    category_num = {}
    words_num = {}
    doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
      pp i
      if i>1
        break
      end
      body = row.css("Data")[0].text
      category = []

      # do features
      document = {:body => body}
      response = @@soap_client.doFeature([document].collect{|p| p.nil? ? "{}" : p.to_json.to_s})

      if response['return'].blank?
        next
      end
      features = response['return'].split("|")[0].split(",")

      all_categories.each_with_index do |c,index|
        data = row.css("Data")[index+1]
        if data.nil?
          pp '---  skip ----'
          next
        end
        value = data.text
        if value == "1"
          category << all_categories[index][0]
        elsif value == "0"
          category << all_categories[index][1]
        else
          next
        end
      end

      category.each do |c|
        if distinct_features[c].nil?
          distinct_features[c] = {}  
        end
        features.each do |feature|
          f = feature.split("=")[0]
          if distinct_features[c][f].nil?
            distinct_features[c][f] = 1
          else
            distinct_features[c][f] += 1
          end
        end
      end
      
      training_data << {:features => features, :category => category}
    end

    pp training_data

    nb = []
    all_categories.each_with_index do |categories,index|
      pp index
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

    prior = {}
    likelihood = {}

    all_categories.each_with_index do |category, index|
      if nb[index]
        a = nb[index].category_probability(category[0])
        b = nb[index].get_likelihood
        prior[category[0]] = a.to_f.round(5)
        likelihood[category[0]] = {}
        b.each do |k, v|
          likelihood[category[0]][k.to_s] = v.to_f.round(5)
        end
      end
    end

    pp prior
    pp likelihood

    # redis.hdel("parameters", "prior")
    # redis.hdel("parameters", "likelihood")
    # redis.hdel("parameters", "version")
    # redis.hset("parameters", "prior", prior.to_json)
    # redis.hset("parameters", "likelihood", likelihood.to_json)
    # need to update when update parameters
    # redis.hset("parameters", "version", 1)

    # pp '[info] === done ==='

    # `rm prior.txt`
    # `rm likelihood.txt`
    # file_a = File.new('prior.txt', 'a+')
    # file_b = File.new('likelihood.txt', 'a+')
    # all_categories.each_with_index do |category, index|
    #   a = nb[index].category_probability(category[0])
    #   b = nb[index].get_likelihood
    #   file_a.puts('"' + category[0] + '"=>' + a.to_f.round(5).to_s + ',')
    #   file_b.puts('"' + category[0] + '"=>{')
    #   b.each do |k, v|
    #     file_b.puts('"' + k.to_s + '"=>' + v.to_f.round(5).to_s + ',')
    #   end
    #   file_b.puts('},')
    # end

    # file_a.close
    # file_b.close

    # classify
    # results = []
    # doc.css("Row")[400..410].each do |row|
    #   body = row.css("Data")[0].text

    #   document = {:body => body}
    #   response = @@soap_client.doFeature([document].collect{|p| p.nil? ? "{}" : p.to_json.to_s})
    #   features = response['return'].split("|")
    #   all_categories.each_with_index do |categories,index|
    #     results << nb[index].classify(features)
    #   end
    #   pp body + results.to_json
    # end
  
  end

  desc "extract features"
  task :features, :environment do |t, args|
    # tag_list = get_tag_list
    tag_list = ['positive','negative']

    all_categories = []
    tag_list.each{|tag| all_categories << [tag, "not_"+tag]}
    # extract training data
    training_data = []
    @@soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver
    doc = Nokogiri::XML(File.open("lib/20150612(positive+negative).xml"))

    category_num = {}
    words_num = {}
    doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
      pp i
      if !row.css("Data")[0]||i>100
        break
      end
      body = row.css("Data")[0].text
      category = []
      # do segmentation
      document = {:body => body}
      response = @@soap_client.doSegmentation([document].collect{|p| p.nil? ? "{}" : p.to_json.to_s})
      words = response['return'].split("|")

      all_categories.each_with_index do |c, index|
        data = row.css("Data")[index+1]
        if data.nil?
          pp '---  skip ----'
          next
        end
        value = data.text
        if value == "1"
          v = 0
        elsif value == "0"
          v = 1
        else
          next
        end

        c = all_categories[index][v]
        category_num[c] ||= 0
        category_num[c] += 1
        words[0].split(",").each do |word|
          w, count = word.split("=")
          words_num[w] ||= {}
          words_num[w][c] ||= 0
          words_num[w][c] += 1
        end
      end
    end

    word_average_prob = {}
    each_word_prob = {}
    prob = {}
    sum = {}
    words_num.each do |word, frequency|
      total_prob = 0
      prob[word] ||= {}
      sum[word] = 0
      frequency.each do |category, count|  
        prob[word][category] = count.to_f / category_num[category]
        total_prob += prob[word][category]
        sum[word] += count
      end

      # delete the words that occur only few times
      if sum[word] > frequency.count * 3
        word_average_prob[word] = total_prob / all_categories.flatten.count
      end
    end
 
    word_standard_variance = {}
    words_num.each do |word, frequency|
      # delete the words that occur only few times
      if sum[word] > frequency.count * 3
        variance = 0     
        frequency.each do |category, count|
          single_prob = count.to_f / category_num[category]
          variance += (word_average_prob[word] - single_prob)**2
        end
        all_categories.flatten.each do |c|
          unless frequency.keys.include?(c)
            variance += (word_average_prob[word] - 0)**2
          end
        end
        variance = variance / all_categories.flatten.count
        word_standard_variance[word] = Math.sqrt(variance)/word_average_prob[word]
      end
    end

    pp word_standard_variance.sort_by { |k,v| -v }

    `rm feature_list.txt`
    file = File.new('feature_list.txt', 'a+')

    threshold = 1.0
    word_standard_variance.sort_by { |k,v| -v }.each do |word|
      if word[1] > threshold
        file.puts(word[0])
      end
    end

    file.close

    pp '[info] === done ==='
  end


  task :words, :environment do |t, args|
    tag_list = ['positive','negative']
    distinct_features = {}

    all_categories = []
    tag_list.each{|tag| all_categories << [tag, "not_"+tag]}
    # extract training data
    training_data = []
    @@soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver
    doc = Nokogiri::XML(File.open("lib/20150612(positive+negative).xml"))

    
    sum = {}
    category_num = {}
    words_num = {}
    doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
      # pp i
      # break if i>100
      pp i if (i%100==0)
      next if i==0
      if !row.css("Data")[0]
        break
      end

      body = row.css("Data")[0].text
      category = []

      words = []
      for i in 2..5 do
        for j in 0..(body.length-i) do
           if (body[j..(i+j-1)].match(/[#@、《》\|：；,\.;\:"'!?&，。！？“”（）()_]|\d|\s+/)==nil)
            ww = {}
            ww['feature'] = body[j..(i+j-1)]
            ww['occurrence'] = 1
            words << ww
           end
        end
      end
      all_categories.each_with_index do |c,index|
        data = row.css("Data")[index+1]
        if data.nil?
          pp '---  skip ----'
          next
        end
        value = data.text
        if value == "1"
          category << all_categories[index][0]
        elsif value == "0"
          category << all_categories[index][1]
        else
          next
        end
      end

      category.each do |c|
        if distinct_features[c].nil?
          distinct_features[c] = {}  
        end
        words.each do |word|
          f = word[:feature]
          if distinct_features[c][f].nil?
            distinct_features[c][f] = 1
          else
            distinct_features[c][f] += 1
          end
        end
      end
      # pp words
      training_data << {:features => words, :category => category}
    end
    # pp training_data

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

    prior = {}
    likelihood = {}

    all_categories.each_with_index do |category, index|
      duplicateWords = []

      if nb[index]
        a = nb[index].category_probability(category[0])
        b = nb[index].get_likelihood
        prior[category[0]] = a.to_f.round(5)
        likelihood[category[0]] = {}
        b.each do |k, v|
          likelihood[category[0]][k.to_s] = v.to_f.round(5)
        end
      end
      likelihood[category[0]].sort_by { |k,v| -v }.each do |word|
        if word[1] > 1
          duplicateWords << word[0]
        end
      end
      file = File.new(category[0]+'_word_list.txt', 'a+')
      duplicateWords.each_with_index do |w,i|
         noDup = true
         for j in -20..20 do
           if (!duplicateWords[i+j].nil? && !duplicateWords[i+j].index(w).nil? && j!=0)
             noDup = false
           end
         end
         if noDup 
          file.puts(w)
         end
      end
      file.close
    end

    # word_average_prob = {}
    # each_word_prob = {}
    # prob = {}
    # i = 0
    # words_num.each do |word, categories|
    #   i+=1
    #   # pp i 
    #   # delete the words that occur only few times
    #   if (sum[word] > 10 && categories.count > 1)
    #     total_prob = 0
    #     prob[word] ||= {}
    #     categories.each do |category, count|  
    #       prob[word][category] = count.to_f / category_num[category]
    #       total_prob += prob[word][category]
    #     end

    #     word_average_prob[word] = total_prob / categories.count
    #   end
    # end
 
    # word_standard_variance = {}
    # words_num.each do |word, categories|
    #   # delete the words that occur only few times
    #   if (sum[word] > 10 && categories.count > 1)

    #     variance = 0     
    #     categories.each do |category, count|
    #       single_prob = count.to_f / category_num[category]
    #       variance += (word_average_prob[word] - single_prob)**2
    #     end
    #     # all_categories.flatten.each do |c|
    #     #   unless categories.keys.include?(c)
    #     #     variance += (word_average_prob[word] - 0)**2
    #     #   end
    #     # end
    #     variance = variance / categories.count
    #     word_standard_variance[word] = Math.sqrt(variance)/word_average_prob[word]
    #   end
    # end

    
    # pp word_standard_variance.sort_by { |k,v| -v }

    # `rm feature_list.txt`

    # duplicateWords=[]
    # threshold = 1.0
    # word_standard_variance.sort_by { |k,v| -v }.each do |word|
    #   if word[1] > threshold
    #     duplicateWords << word[0]
    #   end
    # end


    pp '[info] === done ==='
  end


  task :test, [:category] => :environment do |t, args|

    tag_list = get_tag_list
    all_categories = []
    tag_list.each{|tag| all_categories << [tag, "not_"+tag]}

    distinct_features = {}

    # extract training data
    training_data = []
    testArray=[]

    @@soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver
    doc = Nokogiri::XML(File.open("lib/11000.xml"))

    category_num = {}
    words_num = {}
    doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
      if (Random.rand(15)==1)
        # 3% rows are selected for testing instead of training
         test = {}
         test[:body] = row.css("Data")[0].text
         all_categories.each_with_index do |c,index|
          data = row.css("Data")[index+1]
          if !data.nil?
             test[all_categories[index][0]] = data.text
          end
         end  
         testArray << test
         next     
      end
      body = row.css("Data")[0].text
      category = []

      # do features
      document = {:body => body}
      response = @@soap_client.doFeature([document].collect{|p| p.nil? ? "{}" : p.to_json.to_s})

      if response['return'].blank?
        next
      end
      features = response['return'].split("|")[0].split(",")

      all_categories.each_with_index do |c,index|
        data = row.css("Data")[index+1]
        if data.nil?
          pp '---  skip ----'
          next
        end
        value = data.text
        if value == "1"
          category << all_categories[index][0]
        elsif value == "0"
          category << all_categories[index][1]
        else
          next
        end
      end

      category.each do |c|
        if distinct_features[c].nil?
          distinct_features[c] = {}  
        end
        features.each do |feature|
          f = feature.split("=")[0]
          if distinct_features[c][f].nil?
            distinct_features[c][f] = 1
          else
            distinct_features[c][f] += 1
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

    prior = {}
    likelihood = {}

    all_categories.each_with_index do |category, index|
      if nb[index]
        a = nb[index].category_probability(category[0])
        b = nb[index].get_likelihood
        prior[category[0]] = a.to_f.round(5)
        likelihood[category[0]] = {}
        b.each do |k, v|
          likelihood[category[0]][k.to_s] = v.to_f.round(5)
        end
      end
    end  

    # test
    results = []
    tp = {}
    fp = {}
    tn = {}
    fn = {}
    fp_content = {}
    fn_content = {}
    tag_list.each do |tag|
      tp[tag] = 0
      fp[tag] = 0
      tn[tag] = 0
      fn[tag] = 0
      fp_content[tag] = []     
      fn_content[tag] = []
    end

    testArray.each do |test|
      post_hashs = [{:body => test[:body]}]
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
        
        tag_list.each do |tag|
          predicted[tag] = (prior[tag] || 0)*1 #weight of prior reduced for lack of training data, by ice
          features.each do |feature_str|
            feature = feature_str.split("=")[0]
            count = feature_str.split("=")[1].to_i 
            predicted[tag] += (likelihood[tag] && likelihood[tag][feature] || 0)*(1+Math.log(count))
          end
          predicted[tag] = 1/(1+Math.exp(0-predicted[tag]))
          if  predicted[tag]>0.51
             tp[tag] += 1 if test[tag]=='1'
             fp[tag] += 1 if test[tag]=='0'
             fp_content[tag] << test[:body] if test[tag]=='0'
          else
             tn[tag] += 1 if test[tag]=='0'
             fn[tag] += 1 if test[tag]=='1'
             fn_content[tag] << test[:body] if test[tag]=='1'
          end
        end        
      end
    end

    #output tag precise and recall
    tag_list.each do |tag|
      if (tp[tag]+fp[tag]+fn[tag]>10)
        pp tag+": precise = "+((tp[tag].to_f/(tp[tag]+fp[tag]))*100).round(1).to_s + "%   recall=" + ((tp[tag].to_f/(tp[tag]+fn[tag]))*100).round(1).to_s + "%"
      end
    end

#############################################################################

    #output all precise
    x=0
    y=0
    tag_list.each do |tag|
      x += tp[tag].to_f
      y += tp[tag]+fp[tag]
    end;nil
    pp "Overall precise : " + (x/y*100).to_f.round(1).to_s + "%"

    #output all recall
    m=0
    n=0
    tag_list.each do |tag|
      m += tp[tag].to_f
      n += tp[tag]+fn[tag]
    end;nil
    pp "Overall recall : " + (m/n*100).to_f.round(1).to_s + "%"

    #output txt file (fp)
    file = File.new('fp3.txt', 'a+')
    tag_list.each do |tag|
      file.puts(tag)
      file.puts(fp_content[tag].count)
      file.puts("==================")
      fp_content[tag].each do |c|
        file.puts(c.gsub("\n"," "))
      end
      file.puts("======================================================================")
    end
    file.close

    #output txt file (fn)
    file = File.new('fn3.txt', 'a+')
    tag_list.each do |tag|
      file.puts(tag)
      file.puts(fn_content[tag].count)
      file.puts("==================")
      fn_content[tag].each do |c|
        file.puts(c.gsub("\n"," "))
      end
      file.puts("======================================================================")
    end
    file.close
################################################################################

  end

  desc "debug the prediction"
  task :debug, :environment do |t, args|
    @@tag_list = get_tag_list
    @@likelihood = get_likelihood
    @@prior = get_prior

    body = "亚航假日就是坑爹货。。同一套餐同一天预订，前后才差几分钟，价格就差几百。。大大地欺骗消费者，说是先按最优惠的开始的，结果我前面买的比后面的贵好几百啊，有木有，坑爹啊。。抓住一个能赚一笔是一笔，还不给退订，不给变更，消费者擦亮眼睛，别去买，血淋淋的教训。。@亚航假日"
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
        predicted[tag] = (@@prior[tag] || 0)*1 #weight of prior reduced for lack of training data, by ice
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
    pp predicted
    pp predict_tags
  end

  desc "debug the prediction"
  task :import_from_sdb, [:start_time,:tag] => :environment do |t, args|
    start_time = args[:start_time]
    tag = args[:tag]
    doc = Nokogiri::XML(File.open("trainingdata.xml"))

    p_posts = Post.find(:all,:conditions=>["negtive_tags = ? and created>?",tag,start_time])

    n_posts = Post.find(:all,:conditions=>["negtive_tags = ? and created>?",tag,start_time])

  end
  
end