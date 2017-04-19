require 'rspec'
require_relative '../lib/notify'
require_relative '../lib/domain_info'
require 'date'

describe Notify do
  context 'when there are expiring results' do
    
      before(:each) do    
        @legit_pagerduty_key = ENV['PAGERDUTY_KEY']
        @today = Date.today
      end

      it 'Does not post to Pagerduty due to an invalid key' do
        bad_pagerduty_key = "fakekey"
        bad_domain_info = [DomainInfo.new("example.com", [bad_pagerduty_key], @today.to_s, [1,0])]

        results = Notify.send_notification(bad_domain_info, bad_pagerduty_key)
        expect(results).to be(false)
      end

    it 'Sends Pagerduty notification for a single domain' do
      single_domain_info = [DomainInfo.new("example.com", [@legit_pagerduty_key], @today.to_s, [1,0])]

        results = Notify.send_notification(single_domain_info, @legit_pagerduty_key)
        expect(results).not_to be(false)

    end

    it 'Sends notification for an overdue SSL Certificate' do

      old_date = "1999-09-09"
      overdue_domain_info = [DomainInfo.new("example.com", [@legit_pagerduty_key], old_date, [])]

      results = Notify.send_notification(overdue_domain_info, @legit_pagerduty_key)
      expect(results).not_to be false
    end

    it 'Sends one notification for multiple certificates' do

      multi_domain_info = [DomainInfo.new("example.com", [@legit_pagerduty_key], @today.to_s, [10]),
                           DomainInfo.new("ask.com", [@legit_pagerduty_key], @today.to_s, [10])]

      results = Notify.send_notification(multi_domain_info, @legit_pagerduty_key)
      expect(results).not_to be false
    end

    it 'Sends no notification because we are not X days away' do
      expiry_date = @today + 10
      no_notify_domain_info = [DomainInfo.new("example.com", [@legit_pagerduty_key], expiry_date.to_s, [9])]

      result = Notify.send_notification(no_notify_domain_info, @legit_pagerduty_key)
      expect(result[0].send_alert).to be false # no alert sent
    end

    it 'Notifies because an invalid domain was given' do
      expiry_date = @today + 10
      domain_info = [DomainInfo.new("example.com", [@legit_pagerduty_key], '', [9], 'ERROR!')]

      result = Notify.send_notification(domain_info, @legit_pagerduty_key)
      expect(result).not_to be false
    end


  end


end
