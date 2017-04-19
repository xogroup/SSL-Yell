class DomainInfo

  attr_accessor :domain, :pagerduty_keys, :days_to_notify, :expiry_date, :send_alert, :error

  def initialize(domain, pagerduty_keys, expiry_date, days_to_notify, error='')
    @domain = domain
    @expiry_date = expiry_date
    @days_to_notify = days_to_notify
    @pagerduty_keys = pagerduty_keys
    @error = error
    @send_alert = false
  end

end