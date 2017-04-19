require 'httparty'

class Notify

  ENDPOINT = 'https://events.pagerduty.com/generic/2010-04-15/create_event.json'

  def self.log_results(logger, domain_infos, date_checked)

    domain_infos.each do |domain_info|
      date = 'Date checked: ' + date_checked
      domain = 'Domain: ' + domain_info.domain
      expiry = 'Expiry: ' + (domain_info.expiry_date.nil? ? '' : domain_info.expiry_date)
      alert = 'Pagerduty alert sent?: ' + (domain_info.send_alert ? 'Yes' : 'No')
      if !domain_info.error.empty?
        error = 'Error: ' + domain_info.error
        logger.error date + "\t" + domain + "\t" + expiry + "\t" + alert + "\t" + error
      else
        logger.info date + "\t" + domain + "\t" + expiry + "\t" + alert
      end

    end

  end

  def self.log_error(logger, pagerduty_key)
    logger.error 'Error sending notifications'
  end

  def self.append_message(domain_info, messages, pagerduty_key, message)
    if messages.empty?
      messages = {
        service_key: pagerduty_key,
        event_type: 'trigger',
        description: 'SSL Certificates are expiring soon',
        details: {}
      }
    end
    messages[:details][domain_info.domain.to_sym] = message
    return messages
  end

  def self.append_expiry_message(domain_info, messages, pagerduty_key)
    return append_message(domain_info, messages, pagerduty_key, 'Expires ' + domain_info.expiry_date.to_s)
  end

  def self.send_notification(domain_infos, pagerduty_key)

    today = Date.today
    messages = ''

    local_domain_infos = domain_infos.dup

    local_domain_infos.each do |domain_info|

      if !domain_info.error.empty? # error encountered, send no alert
        next
      end

      days_until_expiry = (Date.parse(domain_info.expiry_date.to_s) - today).to_i

      if days_until_expiry <= 0
         messages = append_expiry_message(domain_info, messages, pagerduty_key)
         domain_info.send_alert = true

      else
        domain_info.days_to_notify.each do |num_days|
          if days_until_expiry == num_days
            messages = append_expiry_message(domain_info, messages, pagerduty_key)
            domain_info.send_alert = true
            break
        end
        end
      end
    end

    if !messages.empty?
    response = HTTParty.post(
        ENDPOINT, body: messages.to_json, header: {'Content-Type' => 'application/json'}
    )
    if response && response.code != 200
      return false
    end
  end

    return local_domain_infos
  end

end