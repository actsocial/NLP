class TfIdf
  attr_reader :documents, :tokenized_documents

  def initialize(start_date, end_date)
    # @documents = documents
    # @tokenized_documents = tokenization(start_date, end_date)
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
  
  def self.idf(start_date, end_date,threshold)
    @total_post_count = ThreadSource.where("date >= '#{start_date}' and date < '#{end_date}'").count
    @idf = Term.find_by_sql("select word, count(DISTINCT(post_id)) idf from terms where post_time >= '#{start_date}' and post_time < '#{end_date}' group by word HAVING(idf) > #{threshold}")
    @results = []
    @idf.each do |idf|
      @results << {
        word: idf.word,
        idf: idf.idf,
        percent: idf.idf.to_f/@total_post_count
      }
    end
    return @results
  end

  def self.trend_top(start_date, end_date, threshold)
    @today_idf = idf(start_date, end_date, 15)
    @thirty_idf = idf(start_date.to_date - 30.days, start_date, 2)
    @results = []
    @today_idf.each do |td_idf|
      th_idf = @thirty_idf.select{|d| d[:word] == td_idf[:word]}.first
      trend = td_idf[:percent]/th_idf[:percent]
      @results << {
        word: td_idf[:word],
        trend: trend
      }
    end
    #return @results.select{|r| r[:trend] >= 3}
    return @results.sort_by{|v| v[:trend]}.reverse[0...30]
  end

  def self.all_top_word()
    @results = {}
    @t10.each do |word|
      @t10.select{|d| d[:word] != word[:word]}.each do |w|
        wa = word[:word] + w[:word]
        @results[wa] = {
          w: [word[:word], w[:word]],
          count: 0
        }
      end
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