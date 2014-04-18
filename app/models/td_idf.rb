class TfIdf
  attr_reader :documents, :tokenized_documents

  def initialize(documents)
    @documents = documents
    @tokenized_documents = tokenization
  end
  
  def tf
    @tf ||= calculate_term_frequencies
  end
  
  def idf
    @idf ||= calculate_inverse_document_frequency
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

  def tokenization
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