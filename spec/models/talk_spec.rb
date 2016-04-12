require 'rails_helper'

RSpec.describe Talk, type: :model do
  let(:required_attr) { [:first_name, :last_name, :target, :title, :subtitle, :time] }

  it 'should not allow save with invalid attributes' do
    talk = Talk.new

    expect(talk.save).to be_falsey
    expect(talk.errors).not_to be_empty
    expect(talk.errors.size).to be == required_attr.length
    expect(talk.errors.keys).to include(*required_attr)
  end

  it 'should not allow save with date less than current day' do
    new_talk = build(:talk_published, date: DateTime.now - 1.day)

    expect(new_talk.save).to be_falsey
    expect(new_talk.errors[:date].size).to eq(1)
  end

  context 'when a talk has already saved' do
    let(:talk) { create(:talk_published) }

    it 'should not allow duplicated title' do
      new_talk = build(:talk, title: talk.title)

      expect(new_talk.save).to be_falsey
      expect(new_talk.errors[:title].size).to eq(1)
      expect(new_talk.errors[:title].first).to include('has already been taken')
    end

    it 'should not allow publish in the same date and time' do
      new_talk = build(:talk, date: talk.date, time: talk.time, published: true)

      expect(new_talk.save).to be_falsey
      expect(new_talk.errors[:date].size).to eq(1)
    end
  end

  context 'list only published' do
    before do
       create_list(:talk, 2)
       create_list(:talk_published, 3)
    end

    it 'should get only published enties' do
      published_list = Talk.published.all.to_a
      expect(published_list).not_to be_empty
      expect(published_list.length).to be == 3
    end
  end

  describe '#number_formated' do
    context 'empty number' do
      let(:talk) { Talk.new }

      it 'should not format and return empty' do
        expect(talk.number_formated).to eq ''
      end
    end

    context 'single-digit number' do
      let(:talk) { Talk.new(number: 5) }

      it 'should format with 2 zeros' do
        expect(talk.number_formated).to eq('005')
      end
    end

    context 'two-digit number' do
      let(:talk) { Talk.new(number: 10) }

      it 'should format with one zero' do
        expect(talk.number_formated).to eq('010')
      end
    end

    context 'three-digit number' do
      let(:talk) { Talk.new(number: 150) }

      it 'should not format' do
        expect(talk.number_formated).to eq('150')
      end
    end
  end

  describe '#title_formated' do
    let(:title) { 'New Talk' }
    let(:talk) { Talk.new(title: title, number: 29) }

    it 'should return "DE Talk #formatted-number - title"' do
      expect(talk.title_formated).to eq("DE Talk #029 - #{title}")
    end
  end

  describe '#title_for_cover_filename' do
    let(:title) { 'New Talk' }
    let(:talk) { Talk.new(title: title, number: 29) }

    it 'should return a string treated for file without space' do
      expect(talk.title_for_cover_filename).to eq('de-talk-029-new-talk')
    end
  end

  describe '#date_str=' do
    let(:talk) { Talk.new }

    context 'invalid string date' do
      let(:invalid_date) { '2014-02-30' }

      it 'should not fill date attribute' do
        talk.date_str = invalid_date

        expect(talk.validate).to be_falsey

        expect(talk.errors[:date_str].size).to eq(1)
        expect(talk.errors[:date_str].first).to include('is invalid')
        expect(talk.date).to be_nil
      end
    end

    context 'valid string date' do
      let(:valid_date) { '2014-02-23' }

      it 'should fill date attribute with DateTime' do
        talk.date_str = valid_date

        expect(talk.date).not_to be_nil
        expect(talk.date).to be_a(Date)
        expect(talk.date).to eq(DateTime.parse(valid_date))
      end
    end
  end

  shared_context 'formatted date' do
    it 'should return a string formatted date' do
      expect(talk.date_str).to be_a String
      expect(talk.date_str).to eq valid_date
    end
  end

  describe '#date_str' do
    context 'with empty date' do
      let(:talk) { Talk.new }

      it 'should return an empty string' do
        expect(talk.date_str).to be_a(String)
        expect(talk.date_str).to be_blank
      end
    end

    context 'with date' do
      let(:talk) { Talk.new(date: DateTime.parse(valid_date)) }

      context 'with default locale' do
        it_behaves_like 'formatted date' do
          let(:valid_date) { '2014-03-12' }
        end
      end

      context 'with default locale pt-br' do
        before { I18n.locale = 'pt-br' }

        it_behaves_like 'formatted date' do
          let(:valid_date) { '12/03/2014' }
        end
      end
    end
  end
end
