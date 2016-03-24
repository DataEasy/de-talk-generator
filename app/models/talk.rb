class Talk < ActiveRecord::Base
  validates :first_name, :last_name, :target, :title, :subtitle, :time, presence: true
  validates :first_name, :last_name, length: { maximum: 10 }
  validates :title, uniqueness: { case_sensitive: false }
  validates :date, uniqueness: { scope: [:published, :time] }
  validates :title, length: { maximum: 30 }
  validates :subtitle, length: { maximum: 45 }
  validates :target, length: { maximum: 65 }
  validate :validate_date

  belongs_to :user

  scope :published, -> { where(published: true) }

  acts_as_taggable

  def title_for_cover_filename
    "de-talk-#{number_formated}-#{title.downcase.gsub(/\s/,'-')}"
  end

  def title_formated
    "DE Talk ##{number_formated} - #{title}"
  end

  def number_formated
    number ? '%03d' % number : ''
  end

  def date_str=(date_str)
    self.date = DateTime.parse(date_str)
  rescue StandardError
    self.date = nil
    @date_str_invalid = true
  end

  def date_str(format = :default)
    date.nil? ? '' : I18n.l(date, format: format)
  end

  private

  def validate_date
    errors.add(:date_str, :invalid) if @date_str_invalid

    validate_date_greater_than_today if published?
  end

  def validate_date_greater_than_today
    if !@date_str_invalid && date.is_a?(Date)
      errors.add(:date, :greater_than_today, value: I18n.l(date, format: :default)) unless date > DateTime.now
    end
  end
end
