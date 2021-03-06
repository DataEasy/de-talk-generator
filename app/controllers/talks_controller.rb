require 'fileutils'

class TalksController < ApplicationController
  before_action :load_cover_service
  before_action :set_talk, only: [:show, :edit, :update, :destroy, :preview_publish, :publish, :preview_cover_image, :cancel]
  before_action :can_change, only: [:edit, :update, :destroy, :preview_publish, :publish]

  autocomplete :tag, :name, class_name: 'ActsAsTaggableOn::Tag'

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

  # GET /talks/1/preview_publish
  def preview_publish
    @talk.number = Talk.published.maximum(:number).to_i + 1

    if Talk.published.where(date: @talk.date, time: @talk.time).exists?
      flash.now[:warning] = "There's a DE Talk scheduled at #{@talk.date}:#{l(@talk.time, format: :very_short)}"
    end
  end

  # PATCH /talks/1/publish
  def publish
    @talk.number = Talk.published.maximum(:number).to_i + 1
    @talk.published = true

    if @talk.save
      begin
        @cover_service.publish_cover @talk
      rescue
        @talk.update!(number: nil, published: false)

        return redirect_to preview_publish_talk_url(@talk), notice: t('messages.talks.fail_publish')
      end

      @talk.filename = "#{@talk.title_for_cover_filename}.png"
      if @talk.save

      ActiveSupport::Notifications.instrument(Detalk::Constants::NOTIFICATIONS_TALK_PUBLISHED, :talk => @talk)

      redirect_to @talk, notice: t('messages.successfully_published', entity: Talk.model_name.human)
      else
        render :preview_publish
      end
    else
      render :preview_publish
    end
  end

  # GET /talks/1/cancel
  def cancel
    return redirect_to talks_path, notice: t('messages.talks.already_canceled') unless @talk.published

    FileUtils.rm(Rails.root.join('public', 'images', @talk.filename), force: true)

    number = @talk.number

    @talk.update!(filename: nil, number: nil, published: false)
    @talk.number = number

    ActiveSupport::Notifications.instrument(Detalk::Constants::NOTIFICATIONS_TALK_CANCELED, :talk => @talk)

    redirect_to talks_path, notice: t('messages.successfully_canceled', entity: Talk.model_name.human)
  end

  # GET /talks/1/preview_cover_image
  def preview_cover_image
    @talk.number = Talk.where(published: true).maximum(:number).to_i + 1
    filename = @cover_service.create_cover(@talk)

    svg_tmp = Rails.root.join('tmp', "#{filename}.svg")
    cover = Rails.root.join('tmp', "#{filename}.png")

    contents = IO.binread(cover)
    FileUtils.rm(cover)
    FileUtils.rm(svg_tmp)

    send_data contents, type: 'image/png', disposition: 'inline'
  end

  # GET /talks/monthly.json
  def monthly
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
                                 :first_name, :last_name, :number, :target, tag_list: [])
  end

  def json_for_autocomplete(items, method, extra_data=[])
    items.collect do |item|
      { id: item.send(method), label: item.send(method) }
    end
  end

  def load_cover_service(service = CoverService.new)
    @cover_service ||= service
  end
end
