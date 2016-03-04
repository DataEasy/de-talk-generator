class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :recoverable, :registerable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable,
         :trackable, :validatable, :authentication_keys => [:username]

  validates :username, :presence => true, :uniqueness => { case_sensitive: false }
  
  def email_required?
    false
  end

  def email_changed?
    false
  end
end
