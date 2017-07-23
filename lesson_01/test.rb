class SecretThing

  def share_secret
    "The secret is #{secret}"
  end

  private

  def secret
    "shhh.. it's a secret!!"
  end
end

p SecretThing.new.share_secret # => "The secret is shhh.. it's a secret!!"
