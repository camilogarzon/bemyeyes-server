class Helper < User
  many :helper_request, :foreign_key => :helper_id, :class_name => "HelperRequest"
  many :helper_points, :foreign_key => :user_id, :class_name => "HelperPoint"
  key :role, String
  
  before_create :set_role

  def set_role()
    self.role = "helper"
  end

  #TODO to be improved with snooze functionality
  def available request=nil, limit=5
    begin
      request_id = request.present? ? request.id : nil
      contacted_helpers = HelperRequest
      .where(:request_id => request_id)
      .fields(:helper_id)
      .all
      .collect(&:helper_id)
      TheLogger.log.error 'contacted helpers'
      TheLogger.log.error contacted_helpers 


      logged_in_users = Token
      .where(:expiry_time.gt => Time.now)
      .fields(:user_id)
      .all
      .collect(&:user_id)

      abusive_helpers = AbuseReport
      .where(:blind_id => request.blind_id)
      .fields(:helper_id)
      .all
      .collect(&:helper_id)
    rescue Exception => e
      TheLogger.log.error e.message
    end
    Helper.where(:id.nin => contacted_helpers,
     :id.nin => abusive_helpers,
     :id.in => logged_in_users,
     "$or" => [
       {:available_from => nil},
       {:available_from.lt => Time.now.utc}
       ]).all.sample(limit)
  end
end
