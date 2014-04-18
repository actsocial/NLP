require 'set'
class TopicDetectController
  def build_post_hash
    @post_hashes = {}
    @features = Set.new
    posts = Post.joins('left join posts_tags on posts.id = posts_tags.post_id left join post_features on posts.id = post_features.post_id').select('posts.id, post_features.feature, post_features.occurrence').where("posts_tags.tag_id = 'revelant.MTC' and posts_tags.value = 1")

    posts.each do |p|
      @features << p.feature
      if @post_hashes[p.id]
        @post_hashes[p.id] << {p.feature => p.occurrence}
      else
        @post_hashes[p.id] = [{p.feature => p.occurrence}]
      end
    end
  end

  def calculate_weight(post_hashs)

  end

  def tf(post, feature)
    return ;
  end

  def idf(feature)

  end

end