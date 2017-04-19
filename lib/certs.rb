require 'google_drive'
require_relative './domain_info'
require 'socket'
require 'open3'
require 'openssl'

class Certs

  DOMAIN_COL = 1
  PAGERDUTY_COL = 2
  DAYS_COL = 3

  DEFAULT_DAYS = [45, 30, 15, 7, 6, 5, 4, 3, 2, 1]

  SUPPRESSION_SIGNAL = '0'

  def initialize

  end

  def open_worksheet(json_filename, spreadsheet_url)
    session = GoogleDrive::Session.from_service_account_key(json_filename)

    spreadsheet = session.spreadsheet_by_url(spreadsheet_url)

    worksheet = spreadsheet.worksheets[0]

    return worksheet
  end

  # error check this!
  def fetch_expiry_date(domain)
    uri = URI.parse("https://" + domain + "/")

    http = Net::HTTP.new(uri.host,uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start do |h|
      @cert = h.peer_cert
    end

    return Date.parse(@cert.not_after.strftime("%Y-%m-%d")).to_s
  end

  # Check that a domain exists
  def verify_domain(domain)
      begin
        Socket.gethostbyname(domain)
      rescue SocketError
        return false
      end

      true
  end

  # Check that every element of an array is an integer
  def int_array_check(arr)
    arr.each do |element|
      Integer(element) != nil rescue return false
    end
    return true
  end

  # Expect a comma-separated list of numbers as input. Ex: 45,30,15,7,6,5,4,3,2,1
  def fetch_csv_array(str) # instance method

   #remove whitespace
   str.gsub!(/\s+/, "")
   return str.split(',')
  end

  # Returns an array of DomainInfo objects from each row of the worksheet
  def fetch_certs_from_worksheet(worksheet) # class method

    domain_infos = Array.new

    (2..worksheet.num_rows).each do |row| # first row is header

      domain = worksheet[row, DOMAIN_COL]

      days_to_notify = fetch_csv_array(worksheet[row, DAYS_COL])

      # Don't use row if it is invalid
      if domain.empty? || !verify_domain(domain) || !int_array_check(days_to_notify)
        $stderr.puts("Error, row " + row.to_s + " of spreadsheet could not be parsed")
        next
      end

      if days_to_notify.empty?
        days_to_notify = DEFAULT_DAYS
      elsif days_to_notify.size == 1 && days_to_notify[0] == SUPPRESSION_SIGNAL
        next
      else
        days_to_notify.map!(&:to_i)
      end

      begin
        expiry_date = fetch_expiry_date(domain)
        error = ''
      rescue => e
        expiry_date = ''
        error = e.inspect
      end

      pagerduty_keys = fetch_csv_array(worksheet[row, PAGERDUTY_COL])

      domain_infos.push(DomainInfo.new(domain, pagerduty_keys, expiry_date, days_to_notify, error))

    end

    return domain_infos
    end

end