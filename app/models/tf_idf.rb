class TfIdf
  attr_reader :documents, :tokenized_documents

  @@soap_client = SOAP::WSDLDriverFactory.new('http://localhost:8083/AxisWS/asia.wildfire.Featurer?wsdl').create_rpc_driver

  def initialize(start_date, end_date)
    # @documents = documents
    # @tokenized_documents = tokenization(start_date, end_date)
  end

  def self.do_segmentation(scope, start_date, end_date)
    results = {}
    threads = WeiboThread.where(:scope => scope, :ymd => start_date...end_date, :topic => 'all').order("thread_id")
    results_arr = []
    threads.each do |t|
      results_arr << {:body => t.title}
    end
    response = @@soap_client.doSegmentation(results_arr.collect{|p| p.nil? ? "{}" : p.to_json.to_s})
    response["return"].split("|").each_with_index do |words, index|
      results[threads[index].thread_id] = {:words => words}
    end
    return results
  end

  def self.tf(start_date, end_date,threshold)
    @tf = Term.find_by_sql("select sum(count) as tf, word from terms where post_time >= '#{start_date}' and post_time < '#{end_date}' group by word HAVING(tf) > #{threshold}")
    @results = []
    @tf.each do |tf|
      @results << {
        word: tf.word,
        tf: tf.tf
      }
    end
    return @results
  end

  def self.idf(scope ,start_date, end_date, threshold)
    threads = WeiboThread.where("scope = '#{scope}' and date >= '#{start_date}' and date < '#{end_date}'");nil
    threads_count = threads.count
    results = {}
    threads.each do |thread|
      response = @@soap_client.doSegmentation([{:body => thread.title}].collect{|p| p.nil? ? "{}" : p.to_json.to_s})
      response["return"].split(",").each do |word|
        word,count = word.split("=")
        results[word] ||= {
          word: word,
          idf: 0,
          percent: 0.0
        }
        results[word][:idf] += 1
        results[word][:percent] = results[word][:idf].to_f/threads_count
      end
    end;nil
    return results.to_a.select{|w| w[1][:idf] > threshold}
  end

=begin  
  def self.idf(scope, start_date, end_date,threshold)
    total_post_count = WeiboThread.where(:scope => scope, :ymd => start_date...end_date, :topic => 'all').count
    idfs = Term.find_by_sql("select word, count(DISTINCT(post_id)) idf from terms where scope = '#{scope}' and post_time >= '#{start_date}' and post_time < '#{end_date}' group by word HAVING(idf) > #{threshold}")
    results = []
    idfs.each do |idf|
      results << {
        word: idf.word,
        idf: idf.idf,
        percent: idf.idf.to_f/total_post_count
      }
    end
    return results
  end
=end  

#动态分词
=begin
  def self.trending_words(today_idfs, thirty_idfs, threshold)
    results = []
    today_idfs.each do |td_idf|
      th_idf = thirty_idfs.select{|d| d[0] == td_idf[0]}.first
      next if th_idf.nil? || th_idf.blank?
      trend = td_idf[1][:percent]/th_idf[1][:percent]
      results << {
        word: td_idf[1][:word],
        trend: trend
      }
    end
    #return results.select{|r| r[:trend] >= threshold}
    return results.sort_by{|v| v[:trend]}.reverse[0...30]
  end
=end  

  def self.trending_words(today_idfs, thirty_idfs, threshold)
    results = []
    today_idfs.each do |td_idf|
      th_idf = thirty_idfs.select{|d| d[:word] == td_idf[:word]}.first
      next if th_idf.nil? || th_idf.blank?
      trend = td_idf[:percent]/th_idf[:percent]
      results << {
        word: td_idf[:word],
        trend: trend
      }
    end
    #return results.select{|r| r[:trend] >= threshold}
    return results.sort_by{|v| v[:trend]}.reverse[0...30]
  end

  def self.generate_bigram(words_trend)
    results = {}
    words = words_trend.map{|w| w[:word]}
    tt_words = words.combination(2).to_a# + words.combination(3).to_a
    tt_words.each do |word|
      wa = word.join
      results[wa] = {
        "word" => word,
        "count" => 0
        # "#{word[0]}" => words_trend.select{|r| r[:word] == word[0]}.first[:trend],
        # "#{word[1]}" => words_trend.select{|r| r[:word] == word[1]}.first[:trend] 
      }
    end
    return results
  end

  def self.get_condition_by_trend_word(scope, start_date, end_date)
    today_idfs = TfIdf.idf(scope, start_date, end_date, 15)
    thirty_idfs = TfIdf.idf(scope, start_date.to_date - 30.days, start_date, 2)
    threshold1 = 2.5
    tw = TfIdf.trending_words(today_idfs,thirty_idfs,threshold1)
    words = tw.collect{|w| w[:word]}
    con = []
    words.each do |word|
      con << "title like '%#{word}%'"
    end
    return "scope = '#{scope}' and (#{con.join(' or ')}) and date >= '#{start_date}' and date < '#{end_date}'"
  end

  def self.topic_detection(start_date, end_date)
    today_idfs = TfIdf.idf(start_date, end_date, 15)
    thirty_idfs = TfIdf.idf(start_date.to_date - 30.days, start_date, 2)
    threshold1 = 2.5
    tw = TfIdf.trending_words(today_idfs,thirty_idfs,threshold1)
    bigrams = generate_bigram(tw)

    # top_words = all_top_word(start_date, end_date)
    threads = ThreadSource.where("date >= '#{start_date}' and date < '#{end_date}'")
    bigrams.each do |words|
      ws = words[1]["word"]
      threads.each do |thread|
        if !thread.title.index(ws[0]).nil? && !thread.title.index(ws[1]).nil?
          bigrams["#{words[0]}"]["count"] += 1
        end
      end
    end
    return bigrams.to_a.select{|a| a[1]["count"]>0}.sort_by{|a| a[1]["count"]}.reverse[0..50]
  end
  
  # tf_idf = tf * idf
  def tf_idf
    tf_idf = tf.map(&:clone)
    
    tf.each_with_index do |document, index|
      document.each_pair do |term, tf_score|
        tf_idf[index][term] = tf_score * idf[term]
      end
    end
    
    tf_idf
  end

  def tokenization(start_date, end_date)
    results = []
    @documents = Term.where('date >= ? and date <= ?', start_date, end_date).group("post_id")

    @documents.each do |document|
      segment = {}
      segment[:terms] = {}
      total_count = 0
      terms.each do |term|
        segment[:terms][term] ||= 0
        segment[:terms][term] += 1
        total_count += 1
      end
      segment[:total_count] = total_count
      results << segment
    end
    results
  end
    

  def total_documents
    @documents.size
  end

  def total_terms
    return @tokenized_documents.map{|document| document[:words].keys}.flatten.uniq
  end


  # TF = times_of_a_term_appear_in_document / number_of_terms_in_document
  # Calculates how frequency a term appears in the document
  def calculate_term_frequencies
    results = []
    
    @tokenized_documents.each do |tokens|
      document_result = {}
      tokens[:words].each do |term, count|
        document_result[term] = (count/tokens[:total_count].to_f).round(6)
      end
      
      results << document_result
    end
    
    results
  end
  
  # IDF = total_documents / number_of_documents_the_term_appears_in
  # This calculates how important a term is.
  def calculate_inverse_document_frequency
    results = {}

    tokenized_documents.each do |document|
      terms = document[:words]
      terms.each_key do |term|
        results[term] ||= 0
        results[term] += 1
      end
    end

    results.each_pair do |term, count|
      results[term] = 1 + Math.log(total_documents.to_f / (count + 1.0))
    end
    
    results
  end
  
end