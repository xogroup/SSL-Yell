require 'rspec'
require_relative '../lib/certs'

describe 'certs' do

  class WorksheetMock

    def initialize(info_array)
      @info_array = info_array
    end

    def num_rows
      @info_array.length
    end

    def [](row, col)
      return @info_array[row - 1][col - 1]
    end

  end

  def validate_date(d)

        begin
          date = Date.parse(d) # throws exception if invalid
          rescue ArgumentError
            return false
        end

      return true
  end

  certs = Certs.new

  it 'gets the hashes of a single domain from worksheet' do

    mock_worksheet = WorksheetMock.new([['HEADER', 'HEADER', 'HEADER'], ['google.com', 'pd_key', '45']])

    domain_infos = certs.fetch_certs_from_worksheet(mock_worksheet)

    expect(domain_infos.length) == 1

    expect(validate_date(domain_infos[0].expiry_date)) # should be a valid date

  end

  it 'gets the certs of multiple domains from worksheet' do

    mock_worksheet = WorksheetMock.new([['HEADER', 'HEADER', 'HEADER'], ['google.com', 'pd_key', ''], ['apple.com', 'pd_key', '']])

    domain_infos = certs.fetch_certs_from_worksheet(mock_worksheet)

    expect(domain_infos.length == mock_worksheet.num_rows)

    for i in 0...domain_infos.length do
      expect(validate_date(domain_infos[i].expiry_date))
    end


  end

  it 'tests using an empty worksheet' do

    mock_worksheet = WorksheetMock.new([[]])

    empty_info = certs.fetch_certs_from_worksheet(mock_worksheet)

    expect(empty_info.empty?)

  end

  it 'tests that timeouts give error information' do
    mock_worksheet = WorksheetMock.new([['HEADER', 'HEADER', 'HEADER'], ['google.com', 'pd_key', '45']])

    allow_any_instance_of(Certs).to receive(:fetch_expiry_date).and_throw(Errno::ETIMEDOUT)

    domain_infos = certs.fetch_certs_from_worksheet(mock_worksheet)

    expect(domain_infos.length) == 1

    expect(domain_infos[0].error).not_to be nil
  end


end