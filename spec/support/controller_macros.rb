module ControllerMacros
  def user_login
    login_with :user, :user
  end

  def login_with(user = :user, mapping = :user)
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[mapping]
      sign_in FactoryGirl.create(user)
    end
  end
end
