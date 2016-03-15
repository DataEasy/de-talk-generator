require 'fileutils'

class TalksController < ApplicationController
  before_action :set_talk, only: [:show, :edit, :update, :destroy, :preview_publish, :publish, :preview_cover_image, :cancel]
  before_action :can_change, only: [:edit, :update, :destroy, :preview_publish, :publish]

  # GET /talks
  # GET /talks.json
  def index
    @talks = Talk.where(user: current_user)
  end

  # GET /talks/1
  # GET /talks/1.json
  def show
  end

  # GET /talks/new
  def new
    @tags_most_used = ActsAsTaggableOn::Tag.most_used(10)
    @talk = Talk.new
  end

  # GET /talks/1/edit
  def edit
    @tags_most_used = @talk.tag_list
  end

  # POST /talks
  # POST /talks.json
  def create
    @talk = Talk.new(talk_params)
    @talk.user = current_user

    respond_to do |format|
      if @talk.save
        format.html { redirect_to @talk, notice: t('messages.successfully_created', entity: Talk.model_name.human) }
        format.json { render :show, status: :created, location: @talk }
      else
        @tags_most_used = @talk.tag_list

        format.html { render :new }
        format.json { render json: @talk.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /talks/1
  # PATCH/PUT /talks/1.json
  def update
    respond_to do |format|
      if @talk.update(talk_params)
        format.html { redirect_to @talk, notice: t('messages.successfully_updated', entity: Talk.model_name.human) }
        format.json { render :show, status: :ok, location: @talk }
      else
        @tags_most_used = @talk.tag_list

        format.html { render :edit }
        format.json { render json: @talk.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /talks/1
  # DELETE /talks/1.json
  def destroy
    @talk.destroy

    respond_to do |format|
      format.html { redirect_to talks_url, notice: t('messages.successfully_destroyed', entity: Talk.model_name.human) }
      format.json { head :no_content }
    end
  end

  def preview_publish
    @talk.number = Talk.published.maximum(:number).to_i + 1

    if Talk.published.where(date: @talk.date, time: @talk.time).exists?
      flash.now[:warning] = "There's a DE Talk scheduled at #{@talk.date}:#{l(@talk.time, format: :very_short)}"
    end
  end

  def publish
    @talk.number = Talk.published.maximum(:number).to_i + 1
    @talk.published = true

    if @talk.save
      begin
        filename = create_detalk_img(@talk)

        tmp_png_path = Rails.root.join('tmp', "#{filename}.png")
        cover_path = Rails.root.join('public', 'images',  "#{@talk.title_for_cover_filename}.png")

        FileUtils.cp tmp_png_path, cover_path
        FileUtils.rm Rails.root.join('tmp', "#{filename}.svg")
        FileUtils.rm tmp_png_path
      rescue
        @talk.number = nil
        @talk.save!

        return redirect_to preview_publish_talk_url(@talk), notice: t('messages.talks.fail_publish')
      end

      @talk.filename = "#{@talk.title_for_cover_filename}.png"
      if @talk.save

      publish_new_detalk_on_slack @talk

      redirect_to @talk, notice: t('messages.successfully_published', entity: Talk.model_name.human)
      else
        render :preview_publish
      end
    else
      render :preview_publish
    end
  end

  def cancel
    return redirect_to talks_path, notice: t('messages.talks.already_canceled') unless @talk.published

    FileUtils.rm(Rails.root.join('public', 'images',  @talk.filename))

    number = @talk.number

    @talk.filename = nil
    @talk.number = nil
    @talk.published = false
    @talk.save!

    @talk.number = number
    publish_detalk_canceled_on_slack @talk

    redirect_to talks_path, notice: t('messages.successfully_canceled', entity: Talk.model_name.human)
  end

  def preview_cover_image
    @talk.number = Talk.where(published: true).maximum(:number).to_i + 1
    filename = create_detalk_img(@talk)

    svg_tmp = Rails.root.join('tmp', "#{filename}.svg")
    cover = Rails.root.join('tmp', "#{filename}.png")

    contents = IO.binread(cover)
    FileUtils.rm(cover)
    FileUtils.rm(svg_tmp)

    send_data contents, type: 'image/png', disposition: 'inline'
  end

  def the_month
    date_start = Date.parse(params[:start])
    date_end = Date.parse(params[:end])

    @talks = Talk.published.where(date: date_start..date_end)

    respond_to do |format|
      format.html { redirect_to talks_url }
      format.json
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_talk
    @talk = Talk.where(id: params[:id], user: current_user).take

    return redirect_to talks_path, notice: t('messages.not_found', entity: Talk.model_name.human) if @talk.nil?
  end

  def can_change
    return redirect_to @talk, notice: t('messages.talks.cant_change') if @talk.published
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def talk_params
    params.require(:talk).permit(:title, :subtitle, :date_str, :time, :filename,
      :first_name, :last_name, :number, :target, {tag_list: []})
  end

  def create_detalk_img(talk)
    max_tag_caracters = 60

    arg_list = [
      "\"s\#{{firstName}}\##{talk.first_name}\#\"",
      "\"s\#{{lastName}}\##{talk.last_name}\#\"",
      "\"s\#{{title}}\##{talk.title}\#\"",
      "\"s\#{{subtitle}}\##{talk.subtitle}\#\"",
      "\"s\#{{date}}\##{talk.date_str(:very_short)}\#\"",
      "\"s\#{{time}}\##{l(talk.time, format: :very_short)}\#\"",
      "\"s\#{{num}}\##{talk.number_formated}\#\"",
      "\"s\#{{keywords}}\##{talk.tag_list.to_s.truncate(max_tag_caracters)}\#\"",
      "\"s\#{{target}}\##{talk.target}\#\""
    ]

    svg_source = Rails.root.join('app', 'assets', 'images', 'Template_DE_Talks.svg')

    filename = "tmp_de_talk-#{SecureRandom.uuid}"
    svg_tmp = Rails.root.join('tmp', "#{filename}.svg")
    png_tmp = Rails.root.join('tmp', "#{filename}.png")

    FileUtils.cp svg_source, svg_tmp

    output_png = Rails.root.join('tmp', png_tmp)

    args = "sed -i'' -e #{arg_list.join(' -e ')} \"#{svg_tmp}\""

    if system(args)
      system("inkscape \"#{svg_tmp}\" -e \"#{output_png}\" &> /dev/null")
      sleep(2) #This sleep is mandatory to wait until inkscape processes the image
    end

    filename
  end

  def publish_new_detalk_on_slack(talk)
    begin
      client = Slack::Web::Client.new

      cover = File.open(Rails.root.join('public', 'images', talk.filename))

      client.files_upload(
          channels: Rails.configuration.detalk['slack']['channel'],
          as_user: false,
          file: Faraday::UploadIO.new(cover, 'image/png'),
          title: "DE Talks ##{talk.number_formated} - #{talk.title}",
          filename: "#{talk.title_for_cover_filename}.png",
          icon_emoji: ':de_bot:'
      )

      cover.close

      client.chat_postMessage(
          channel: Rails.configuration.detalk['slack']['channel'],
          text: Rails.configuration.detalk['slack']['message'],
          as_user: false,
          icon_emoji: ':de_bot:'
      )
    rescue Exception => error
      logger.error error
    end
  end

  def publish_detalk_canceled_on_slack(talk)
    begin
      client = Slack::Web::Client.new

      message = Rails.configuration.detalk['slack']['message_talk_canceled'] % talk.title_formated

      client.chat_postMessage(
          channel: Rails.configuration.detalk['slack']['channel'],
          text: message,
          as_user: false,
          icon_emoji: ':de_bot:'
      )
    rescue Exception => error
      logger.error error
    end
  end
end
