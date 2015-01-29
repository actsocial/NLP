class TfIdf
  attr_reader :documents, :tokenized_documents

  @@soap_client = SOAP::WSDLDriverFactory.new('http://localhost:8081/AxisWS/asia.wildfire.Featurer?wsdl').create_rpc_driver
  @@corpus = Lda::Corpus.new

  def initialize(start_date, end_date)
    # @documents = documents
    # @tokenized_documents = tokenization(start_date, end_date)
  end

  # TfIdf.all_days_unigram_detection("ABBOTT","2014-11-26","2014-12-29")
  def self.single_day_unigram_detection(scope,start_date, end_date)
    low_threshold  = 0.0003
    high_threshold = 0.0018
    velocity = 2

    threads_words = do_segmentation(scope, start_date.to_s, end_date.to_s)
    today_tfs = TfIdf.tf(threads_words, low_threshold,high_threshold)

    thirty_threads_words = do_segmentation(scope, (start_date.to_date - 30.days).to_s, start_date.to_s)
    thirty_tfs = TfIdf.tf(thirty_threads_words, low_threshold,high_threshold)

    tw = TfIdf.trending_words(today_tfs,thirty_tfs,velocity)
    
    return tw
  end


  def self.all_days_unigram_detection(scope,start_date, end_date)
    low_threshold = 0.0005
    high_threshold = 0.005    
    velocity = 4

    tw = {}
    all_threads_words = do_segmentation(scope, start_date.to_s, end_date.to_s )

    all_tfs = TfIdf.tf(all_threads_words, low_threshold,high_threshold)

    day = Time.parse(start_date)
    while day<end_date
      threads_words = do_segmentation(scope, day.to_s, (day+1.day).to_s,)
      current_day_tfs = TfIdf.tf(threads_words, low_threshold,1)
      tw[day.to_s] = TfIdf.trending_words(current_day_tfs,all_tfs,velocity)
      # pp day.to_s
      # pp tw[day.to_s]
      day += 1.day
    end
    pp tw

    return tw
  end


  def self.single_day_bigram_detection(scope,start_date, end_date)
    least_occurance = 10
    velocity = 2.5

    today_idfs = TfIdf.idf(scope, start_date.to_s, end_date.to_s, least_occurance)
    thirty_idfs = TfIdf.idf(scope, (start_date.to_date - 30.days).to_s, start_date.to_s, least_occurance)

    tw = TfIdf.trending_words(today_idfs,thirty_idfs,velocity)

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

  def self.get_thread_andwords(scope, start_date, end_date)

  end

  def self.do_feature(scope, start_date, end_date)
    results = {}
    threads = WeiboThread.where(:scope => scope, :ymd => start_date...end_date, :topic => 'all').group("user_name,title").order("thread_id")
    i = 0
    threads.each_slice(100) do |threads_arr|
      results_arr = []
      threads_arr.each do |t|
        results_arr << {:body => t.title}
      end
      response = @@soap_client.doFeature(results_arr.collect{|p| p.nil? ? "{}" : p.to_json.to_s})
      response["return"].split("|").each_with_index do |words, index|
        results[threads[index+i].thread_id] = {:words => words.split(",").map{|w| w.split("=")[0]}.join(',')}
      end
      i += 100
    end
    return results
  end

  def self.do_segmentation(scope, start_date, end_date)
    results = {}
    threads = WeiboThread.where(:scope => scope, :ymd => start_date...end_date, :topic => 'all').group("user_name,title").order("thread_id")
    results_arr = []
    threads.each do |t|
      results_arr << {:body => t.title}
    end
    response = @@soap_client.doSegmentation(results_arr.collect{|p| p.nil? ? "{}" : p.to_json.to_s})
    response["return"].split("|").each_with_index do |words, index|
      results[threads[index].thread_id] = {:words => words.split(",").map{|w| w.split("=")[0]}.join(',')}
    end
    return results
  end

  def self.tf(threads_words, low_threshold,high_threshold)
    results = {}
    document_count = threads_words.count
    total_words_count = 0
    threads_words.each do |thread_id, words|
      words = words.values[0].split(",")
      words.each do |word|
        results[word] ||= {
          word: word,
          occurance: 0,
          tf: 0.0
        }
        results[word][:occurance] += 1
        # results[word][:tf] = results[word][:tf].to_f/document_count
      end
      total_words_count += words.count
    end
    results.each do |word|
      word[1][:tf] = word[1][:occurance].to_f/total_words_count
      if (@@corpus.stopwords.include?(word[1][:word]))
        word[1][:tf] = 0
      end
    end

    return results.to_a.select{|w| (w[1][:tf] > low_threshold && w[1][:tf] < high_threshold) }
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

  def self.trending_words(today_tfs, thirty_tfs, threshold)
    results = []
    today_tfs.each do |td_tf|
      th_idf = thirty_tfs.select{|d| d[0] == td_tf[0]}.first
      next if th_idf.nil? || th_idf.blank?
      trend = td_tf[1][:tf]/th_idf[1][:tf]
      results << {
        word: td_tf[1][:word],
        trend: trend
      }
    end
    return results.select{|r| r[:trend] >= threshold}
    # return results.sort_by{|v| v[:trend]}.reverse[0...30]
  end

=begin
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
=end

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
    least_occurance = 10
    velocity = 2.5

    today_idfs = TfIdf.idf(scope, start_date.to_s, end_date.to_s, least_occurance)
    thirty_idfs = TfIdf.idf(scope, (start_date.to_date - 30.days).to_s, start_date.to_s, least_occurance)

    tw = TfIdf.trending_words(today_idfs,thirty_idfs,velocity)

    words = tw.collect{|w| w[:word]}
    con = []
    words.each do |word|
      con << "title like '%#{word}%'"
    end

    if con.blank?
      return "scope = '#{scope}' and ymd >= '#{start_date}' and ymd < '#{end_date}' and topic = 'all' "
    else
      return "scope = '#{scope}' and (#{con.join(' or ')}) and ymd >= '#{start_date}' and ymd < '#{end_date}' and topic = 'all' "
    end
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
