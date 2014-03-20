class NaiveBayes
	# provide a list of categories and distinct feature nums for this classifier
  attr_accessor :total_distinct_features

  def initialize(categories, features_num)
    # the features count for each category
    @features = Hash.new
    @total_features = 0
    # the number of documents trained for each category
    @categories_documents = Hash.new
    @total_documents = 0
    @threshold = 1.0
    @total_distinct_features = features_num
    @categories = categories

    # the number of features in each category
    @categories_features = Hash.new

    categories.each { |category|
      @features[category] = Hash.new
      @categories_documents[category] = 0
      @categories_features[category] = 0
    }
  end

  def get_likelihood
    likelihood = {}
    smoother1 = 3
    smoother2 = smoother1*(@categories_features[@categories[1]].to_f / @categories_features[@categories[0]].to_f)
    @features[@categories[0]].each_key do |feature|   
      likelihood[feature] = Math.log(feature_probability(@categories[0], feature,smoother1).to_f / feature_probability(@categories[1], feature,smoother2))
    end

    # for those features only shows in negative tag
    @features[@categories[1]].each_key do |feature|   
      likelihood[feature] = Math.log(feature_probability(@categories[0], feature,smoother1).to_f / feature_probability(@categories[1], feature,smoother2))
    end
    likelihood
  end

  # the probability of a category
  # this is the probability that any random document being in this category
  # P(Ci) = number of docs in category Ci / total number of docs
  def category_probability(category)
    Math.log(@categories_documents[category].to_f/@total_documents.to_f)
  end

  # private 
  # the probability of a feature in this category
  # Laplace smoothing
  # P(Fi|Cj) = (features Fi count in category Cj + 1) / (number of features in category Ci + number of distinct features)
  def feature_probability(category, feature, smoother)
    (@features[category][feature].to_f + smoother)/(@categories_features[category].to_f + @total_distinct_features[category]/10)
  end 

  # train the document
  def train(category, document)
    features_count(document).each do |feature, count|
      @features[category][feature] ||= 0
      @features[category][feature] += count
      @categories_features[category] += count
    end
    @categories_documents[category] += 1
    @total_documents += 1
  end

  # get a hash of the number of times a feature appears in any document
  def features_count(document)
    features_frequency = Hash.new
    document.each do |features|
      feature = features['feature']
      count = features['occurrence']
      features_frequency[feature] = count.to_i
    end
    return features_frequency
  end

  # # find the prior for each category
  # def probabilities(document)
  #   probabilities = Hash.new
  #   @features.each_key {|category|
  #     probabilities[category] = probability(category, document)
  #   }
  #   return probabilities
  # end

  # # classify the document into one of the categories
  # def classify(document, default='unknown')
  #   sorted = probabilities(document).sort {|a,b| b[1]<=>a[1]}
  #   best, second_best = sorted.pop, sorted.pop
  #   if best[1]/second_best[1] < @threshold
  #   	best[0]
  # 	else
	 # 		second_best[0]
	 # 	end
  # end

  # # do cross validation
  # def cross_validation(documents)
    
  # end

  # def prettify_probabilities(document)
  #   probs = probabilities(document).sort {|a,b| b[1]<=>a[1]}
  #   totals = 0
  #   pretty = Hash.new
  #   probs.each { |prob| totals += prob[1]}
  #   probs.each { |prob| pretty[prob[0]] = "#{prob[1]/totals * 100}%"}
  #   return pretty
  # end



  # # the probability of a document in this category
  # def doc_probability(category, document)
  #   doc_prob = 0
  #   features_count(document).each { |feature| doc_prob += Math.log(feature_probability(category, feature[0])) }
  #   return doc_prob
  # end



  # # the un-normalized probability of that this document belongs to this category
  # def probability(category, document)
  #   category_probability(category) + doc_probability(category, document)
  # end



end
