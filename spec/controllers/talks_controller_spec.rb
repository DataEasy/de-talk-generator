require 'rails_helper'

RSpec.describe TalksController, type: :controller do
  user_login

  let(:valid_attributes) do
    attributes_for(:talk)
  end

  let(:invalid_attributes) {
    attributes = attributes_for(:talk)
    attributes[:title ] = nil
    attributes
  }

  before do
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'en,pt-BR;q=0.7,en-US;q=0.3'
  end

  describe 'GET #index' do
    it 'assigns all talks from current user' do
      talk = create(:talk, user: subject.current_user)
      create(:talk, user: create(:another_user))

      expect(Talk.count).to eq(2)

      get :index

      talks = assigns(:talks)

      expect(talks.length).to eq(1)
      expect(talks).to eq([talk])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested talk as @talk' do
      talk = create(:talk, user: subject.current_user)

      get :show, { id: talk.to_param }

      expect(assigns(:talk)).to eq(talk)
    end
  end

  describe 'GET #new' do
    it 'assigns a new talk as @talk' do
      get :new

      expect(assigns(:talk)).to be_a_new(Talk)
      expect(assigns(:tags_most_used)).to be_empty
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested talk as @talk' do
      talk = create(:talk, user: subject.current_user)

      get :edit, { id: talk.to_param }

      expect(assigns(:talk)).to eq(talk)
      expect(assigns(:tags_most_used)).to be_empty
    end
  end

  describe 'GET #preview_publish' do
    context 'when date and time are ok' do
      it 'should render withou warning' do
        create(:talk_published, number: 1, date: DateTime.now + 1.day, user: subject.current_user)
        talk = create(:talk, number: nil, date: DateTime.now + 2.day, user: subject.current_user)

        next_number_expected = Talk.published.maximum(:number).to_i + 1

        get :preview_publish, { id: talk.to_param }

        expect(assigns(:talk).number).to eq(next_number_expected)
        expect(flash[:warning]).not_to be_present
      end
    end

    context 'when has a talk published in same date and time' do
      let(:talk_date) { DateTime.now + 1.day }

      it 'should warning about DE Talk scheduled at the same time' do
        create(:talk_published, number: 1, date: talk_date, time: '17:00', user: subject.current_user)
        talk = create(:talk, number: nil, date: talk_date, time: '17:00', user: subject.current_user)

        get :preview_publish, { id: talk.to_param }

        expect(flash[:warning]).to be_present
        expect(flash[:warning]).to include("There's a DE Talk scheduled at")
      end
    end
  end

  describe 'GET #preview_cover_image' do
    before do
      @talk = create(:talk, user: subject.current_user)

      @cover_service_mock = instance_double('CoverService')
      allow(CoverService).to receive(:new).with(any_args).and_return(@cover_service_mock)
      allow(@cover_service_mock).to receive(:create_cover).with(@talk).and_return("tmp_de_talk-#{SecureRandom.uuid}")

      allow(IO).to receive(:binread).with(instance_of(Pathname)).and_return('some content')
      allow(FileUtils).to receive(:rm).with(instance_of(Pathname)).twice
    end

    it 'should increment and set the possible next talk number ' do
      expect { patch :preview_cover_image, { id: @talk.to_param } }.not_to change{ Talk.published.maximum(:number) }

      next_number_expected = Talk.published.maximum(:number).to_i + 1

      expect(assigns(:talk).number).to eq(next_number_expected)
    end

    it 'should create a temporary cover' do
      expect(@cover_service_mock).to receive(:create_cover).with(@talk)
      expect(IO).to receive(:binread).with(instance_of(Pathname)).and_return('some content')
      expect(FileUtils).to receive(:rm).with(instance_of(Pathname)).twice

      get :preview_cover_image, { id: @talk.to_param }

      expect(response.headers['Content-Transfer-Encoding']).to eq('binary')
      expect(response.header['Content-Type']).to eq('image/png')
      expect(response.header['Content-Disposition']).to include('inline')
    end
  end

  describe 'GET #cancel' do
    context 'when the talk is published' do
      before do
        @talk = create(:talk_published, user: subject.current_user)

        allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
        allow(ActiveSupport::Notifications).to receive(:instrument).with(Detalk::Constants::NOTIFICATIONS_TALK_CANCELED, :talk => @talk)
        allow(Talk).to receive_message_chain(:where, :take) { @talk }
      end

      it 'should fire a notification' do
        expect(ActiveSupport::Notifications).to receive(:instrument).with(Detalk::Constants::NOTIFICATIONS_TALK_CANCELED, :talk => @talk)

        get :cancel, { id: @talk.to_param }
      end

      it 'should update filename, number and published' do
        expect(@talk).to receive(:update!).with(filename: nil, number: nil, published: false)
        expect(@talk).to receive(:number=).with(@talk.number)

        get :cancel, { id: @talk.to_param }
      end

      it 'should redirect to index with successful message' do
        get :cancel, { id: @talk.to_param }

        expect(response).to redirect_to(talks_path)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to include('Talk was successfully canceled')
      end
    end

    context 'when the talk is not published' do
      it 'should redirect and set a notice message' do
        talk = create(:talk, user: subject.current_user)

        get :cancel, { id: talk.to_param }

        expect(response).to redirect_to(talks_path)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to include('This DE Talk has already canceled')
      end
    end
  end

  describe 'GET #monthly' do
    it 'assigns the requested talk as @talk' do
      attrs = attributes_for(:talk_published).merge({ date: DateTime.parse("2016-03-15") })
      Talk.new(attrs).save(validate: false)

      (1..3).each do |day|
        attrs = attributes_for(:talk_published).merge({ date: DateTime.parse("2016-04-#{day}") })
        Talk.new(attrs).save(validate: false)
      end

      attrs = attributes_for(:talk_published).merge({ date: DateTime.parse('2016-05-20') })
      Talk.new(attrs).save(validate: false)

      expect(Talk.count).to eq(5)

      get :monthly, { start: '2016-04-01', end: '2016-04-30' }

      expect(assigns(:talks).length).to eq(3)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Talk' do
        expect { post :create, { talk: valid_attributes} }.to change(Talk, :count).by(1)
      end

      it 'assigns a newly created talk as @talk' do
        post :create, { talk: valid_attributes }

        expect(assigns(:talk)).to be_a(Talk)
        expect(assigns(:talk)).to be_persisted
      end

      it 'redirects to the created talk' do
        post :create, { talk: valid_attributes }

        expect(response).to redirect_to(Talk.last)
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved talk as @talk' do
        post :create, { talk: invalid_attributes }

        expect(assigns(:talk)).to be_a_new(Talk)
        expect(assigns(:tags_most_used)).to be_empty
      end

      it "re-renders the 'new' template" do
        post :create, { talk: invalid_attributes }

        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) {
        { title: 'Conflict management', first_name: 'John', last_name: 'Wick' }
      }

      it 'updates the requested talk' do
        talk = create(:talk, user: subject.current_user)

        put :update, { id: talk.to_param, talk: new_attributes}

        talk.reload

        expect(talk.title).to eq(new_attributes[:title])
        expect(talk.first_name).to eq(new_attributes[:first_name])
        expect(talk.last_name).to eq(new_attributes[:last_name])
      end

      it 'assigns the requested talk as @talk' do
        talk = create(:talk, user: subject.current_user)

        put :update, { id: talk.to_param, talk: valid_attributes }

        expect(assigns(:talk)).to eq(talk)
      end

      it 'redirects to the user' do
        talk = create(:talk, user: subject.current_user)

        put :update, { id: talk.to_param, talk: valid_attributes}

        expect(response).to redirect_to(talk)
      end
    end

    context 'with invalid params' do
      it 'assigns the talk as @talk' do
        talk = create(:talk, user: subject.current_user)

        put :update, { id: talk.to_param, talk: invalid_attributes }

        expect(assigns(:talk)).to eq(talk)
      end

      it "re-renders the 'edit' template" do
        talk = create(:talk, user: subject.current_user)

        put :update, { id: talk.to_param, talk: invalid_attributes }

        expect(response).to render_template('edit')
      end
    end
  end

  describe 'PATCH #publish' do
    before(:example) do
      @talk = create(:talk, time: '17:00', user: subject.current_user)
    end

    context 'when everything goes right' do
      before do
        create(:talk_published, number: 1, user: subject.current_user)

        allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
        allow(ActiveSupport::Notifications).to receive(:instrument).with(Detalk::Constants::NOTIFICATIONS_TALK_PUBLISHED, :talk => @talk)

        @cover_service_mock = instance_double('CoverService')
        allow(CoverService).to receive(:new).with(any_args).and_return(@cover_service_mock)
        allow(@cover_service_mock).to receive(:publish_cover).with(@talk)
      end

      it 'should increment and set the next de talk number and as published' do
        next_number_expected = Talk.published.maximum(:number).to_i + 1

        patch :publish, { id: @talk.to_param }

        expect(assigns(:talk).number).to eq(next_number_expected)
        expect(assigns(:talk).published).to be_truthy
      end

      it 'should fire a notification' do
        expect(ActiveSupport::Notifications).to receive(:instrument).with(Detalk::Constants::NOTIFICATIONS_TALK_PUBLISHED, :talk => @talk)

        patch :publish, { id: @talk.to_param }
      end

      it 'should create the de talk cover' do
        next_number_expected = Talk.published.maximum(:number).to_i + 1

        expect(@cover_service_mock).to receive(:publish_cover).with(@talk)

        patch :publish, { id: @talk.to_param }

        @talk.number = next_number_expected
        expect(assigns(:talk).filename).to eq("#{@talk.title_for_cover_filename}.png")
      end

      it 'should redirect to show with sucessful message' do
        patch :publish, { id: @talk.to_param }

        expect(response).to redirect_to(talk_path(@talk))
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to include('Talk was successfully published')
      end
    end

    context 'when has a validation error' do
      it 'should not publish and render preview_publish view' do
        create(:talk_published, date: @talk.date, time: '17:00', user: subject.current_user)

        patch :publish, { id: @talk.to_param }

        expect(response).to render_template(:preview_publish)
      end
    end

    context 'when it is not able to create the cover' do
      before do
        @cover_service_mock = instance_double('CoverService')
        allow(CoverService).to receive(:new).with(any_args).and_return(@cover_service_mock)
        expect(@cover_service_mock).to receive(:publish_cover).with(@talk).and_raise(StandardError)
      end

      it 'should reverse the number and published attributes' do
        patch :publish, { id: @talk.to_param }

        @talk.reload

        expect(response).to redirect_to(preview_publish_talk_url(@talk))
        expect(@talk.number).to be_nil
        expect(@talk.published).to be_falsey
      end

      it 'should redirect to preview_publish with error message' do
        patch :publish, { id: @talk.to_param }

        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to include('Fail to publish the DE Talk')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested user' do
      talk = create(:talk, user: subject.current_user)

      expect(Talk.count).to eq(1)

      expect { delete :destroy, { id: talk.to_param } }.to change(Talk, :count).by(-1)
    end

    it 'redirects to the talks list' do
      talk = create(:talk, user: subject.current_user)

      delete :destroy, { id: talk.to_param }

      expect(response).to redirect_to(talks_url)
    end
  end

end
