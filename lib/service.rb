require "google/cloud/firestore"

class Service
  def initialize
    @firestore = Google::Cloud::Firestore.new
  end

  def users
    @firestore.col(:yourname_users)
  end

  def user(email)
    ref = users.doc(email)
    ref.get
  end
end
