#!/usr/bin/env ruby

require_relative '../lib/certs'
require_relative '../lib/notify'
require 'getoptlong'

EXIT_FAIL = 2

params = GetoptLong.new(
                       ['--help', '-h', GetoptLong::NO_ARGUMENT],
                       ['--sheet', '-s', GetoptLong::REQUIRED_ARGUMENT],
                       ['--json', '-j', GetoptLong::REQUIRED_ARGUMENT],
                       ['--out', '-o', GetoptLong::REQUIRED_ARGUMENT],
                       ['--scheduled', GetoptLong::REQUIRED_ARGUMENT]
)

params.quiet = true

HELP_MESSAGE = "Usage: " + $0 + " --sheet spreadsheet_name --json json_filename [--out logfile] [--scheduled seconds_per_run]"

help_needed = false

spreadsheet = nil
json_filename = nil
logger = nil
schedule = 0

params.each do |opt, arg|
  case opt
    when '--help'
      help_needed = true
    when '--sheet'
      spreadsheet = arg
    when '--json'
      json_filename = arg
    when '--out'
      if arg == 'stdout'
        STDOUT.sync = true
        logger = Logger.new STDOUT
      else
        f = File.new(arg, 'w')
        f.sync = true
        logger = Logger.new f
      end
    when '--scheduled'
      schedule = arg.to_i
    else
      puts("Invalid command " + opt)
      help_needed = true
  end
end

if help_needed || spreadsheet == nil || json_filename == nil
  STDERR.puts(HELP_MESSAGE)
  return
end

#logger.sync = true

# loop if we have scheduled a timeframe (break if not)
while true

  certs = Certs.new

  begin
    worksheet = certs.open_worksheet(json_filename, spreadsheet)
  rescue Errno::ENOENT # invalid json file
    STDERR.puts("Error: could not find json file " + json_filename)
    exit EXIT_FAIL
  rescue GoogleDrive::Error
    STDERR.puts("Error: could not find Google Drive URL " + spreadsheet)
    exit EXIT_FAIL
  end

  domain_infos = certs.fetch_certs_from_worksheet(worksheet)

  # If a domain has N > 1 pagerduty keys: create N objects,
  # each containing only one key.
  # Later, we use this to group by pagerduty keys.

  domain_infos = domain_infos.flat_map { |domain_info|
    num_keys = domain_info.pagerduty_keys.size
    if num_keys > 1
      arr = Array.new(num_keys)
      for i in 0...domain_info do
        arr[i] = domain_info.clone
        arr[i].pagerduty_keys = [domain_info.pagerduty_keys[i]]
      end
      arr
    else
      domain_info
    end
  }

  hashes_by_key = domain_infos.group_by { |info|
    info.pagerduty_keys[0]
  }

  # send at most one notification to each group
  hashes_by_key.each do |pd_key, expiry_hashes|

    notification_sent = Notify.send_notification(expiry_hashes, pd_key)

    if !notification_sent
      logger.error 'Could not send notifications to Pagerduty integration key ' + pd_key
    else
      expiry_hashes = notification_sent
    end

    if logger != nil
      Notify.log_results(logger, expiry_hashes, Date.today.to_s)
    end

  end

  if schedule <= 0
    break
  else
    sleep schedule
  end

end