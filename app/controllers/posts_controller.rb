require 'soap/wsdlDriver'

class PostsController < ApplicationController

  def index
    @tags = Tag.all
    @posts = Post.paginate(:page => params[:page], :per_page => 30)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @posts }
    end
  end

  def show
    @post = Post.find(params[:id])
    tagList = @post.post_tags
    @post[:tags] = {}
    tagList.each do |post_tag|
      @post[:tags][post_tag[:tag_id].gsub(".", "-")] = post_tag[:value]
    end
    respond_to do |format|
      format.html
      format.json { render json: @post }
    end

  end

  def new
    @post = Post.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @post }
    end
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
  end

  def create
    @post = Post.new(params[:post])

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render json: @post, status: :created, location: @post }
      else
        format.html { render action: "new" }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /posts/1
  # PUT /posts/1.json
  def update
    @post = Post.find(params[:id])

    respond_to do |format|
      if @post.update_attributes(params[:post])
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post = Post.find(params[:id])
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url }
      format.json { head :no_content }
    end
  end

  def select_tag
    begin
      session[:selected_tag] = params[:selected_tag]
      if params[:do_action] == "add"
        session[:selected_tag].push(params[:tag])
      elsif params[:do_action] == "remove"
        session[:selected_tag].delete(params[:tag]);
      end
      respond_to do |format|
        format.json {render json: {"status" => "ok"}}
      end
    rescue Exception => e
      puts e
    end
  end

  def change_tag
    begin
      case params[:value]
        when "1"
          post_tag = PostTag.find(:first, :conditions => ["post_id = ? and tag_id = ?", params[:post_id], params[:tag]])
          post_tag.value = 0
          post_tag.save
        when "0"
          PostTag.find(:first, :conditions => ["post_id = ? and tag_id = ?", params[:post_id], params[:tag]]).destroy
        when "N/A"
          post_tag = PostTag.new
          post_tag.post_id = params[:post_id]
          post_tag.tag_id = params[:tag]
          post_tag.value = 1
          post_tag.save
      end
      respond_to do |format|
        format.json { render json: post_tag }
      end
    rescue Exception => e
      puts e
    end
  end

  def do_feature # Do feature after update features
    post_ids = params[:post_ids]
    soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver
    posts = Post.where({:id => post_ids})
    Post_Feature.delete_all({:post_id => post_ids})

    posts.each do |post|
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
    respond_to do |format|
      format.json {render json: {status => "ok"}}
    end
  end

  def import_data # Select
    file = params[:file]['file']
    begin
      @@doc = Nokogiri::XML(file)
      all_post_contents = []
      Post.select("content").each do |p|
        all_post_contents << p.content
      end
      @exist_posts = []
      @new_posts = []
      @tag_list = []
      @@doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
        # read taglist
        if (i==0 && row.css("Data").count>1)
          row.css("Data")[1..-1].each do |tag|
            @tag_list << tag.text
          end
          next
        end

        body = row.css("Data")[0].text
        if all_post_contents.include?(body)
          @exist_posts << {:content => body}
        else
          @new_posts << {:content => body}
        end
      end
      respond_to do |format|
        format.html
      end
    rescue Exception => e
      puts e
    end
  end

  def confirm_import # Import
    begin
      new_posts = []
      tag_list = []
      soap_client = SOAP::WSDLDriverFactory.new(Settings.feature_ws_url).create_rpc_driver

      all_post_contents = []
      Post.select("content").each do |p|
        all_post_contents << p.content
      end

      @@doc.css("Worksheet").first.css("Row").each_with_index do |row, i|
        # read taglist
        if (i==0 && row.css("Data").count>1)
          row.css("Data")[1..-1].each do |tag|
            tag_list << tag.text
          end
          next
        end

        body = row.css("Data")[0].text
        if all_post_contents.include?(body)
          next
        else
          p = Post.new
          p.content = body
          p.save
          new_posts << p

          ###################################
          document = {:body => body}
          response = soap_client.doFeature([document].collect { |p| p.nil? ? "{}" : p.to_json.to_s })
          if response['return'].blank?
            next
          end
          pfs = []
          features = response['return'].split("|")[0].split(",")
          features.each do |feature|
            f = feature.split("=")[0]
            occurrence = feature.split("=")[1]
            pf = PostFeature.new
            pf.post_id = p.id
            pf.feature = f
            pf.occurrence = occurrence.to_i
            pfs << pf
          end
          PostFeature.import pfs
          ###################################

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
      end
=begin
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
            pf = PostFeature.new
            pf.post_id = post.id
            pf.feature = f
            pf.occurrence = occurrence.to_i
            pfs << pf
          end
          PostFeature.import pfs
        end
      end
=end
      respond_to do |format|
        format.json { render json: {"status" => "ok"} }
      end
    rescue Exception => e
      puts e
    end
  end

  def get_features
    post_id = params["post_id"]
    features = Post.find(post_id).post_features
    respond_to do |format|
      format.json { render json: {"features" => features} }
    end
  end

  def change
    puts params
    respond_to do |format|
      format.json { render json: {"status" => "ok"} }
    end
  end

end
