class Talk < ActiveRecord::Base
  validates :first_name, :last_name, :target, :title, :subtitle, :date, :time, presence: true
  validates :first_name, :last_name, length: { maximum: 10 }
  validates :title, uniqueness: { case_sensitive: false }
  validates :date, uniqueness: { scope: [:published, :time] }

  def self.date_taken
    I18n.t('.date.taken', value: I18n.l(date))
  end

  validates :title, length: { maximum: 30 }
  validates :subtitle, length: { maximum: 45 }
  validates :target, length: { maximum: 65 }

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
end
