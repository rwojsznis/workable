require 'spec_helper'

describe Workable::Client do

  describe 'initialization' do
    it 'raises an error on missing api_key / subdomain' do
      expect { described_class.new }.to raise_error(Workable::Errors::InvalidConfiguration)
      expect { described_class.new(api_key: 'key') }.to raise_error(Workable::Errors::InvalidConfiguration)
      expect { described_class.new(subdomain: 'subdomain') }.to raise_error(Workable::Errors::InvalidConfiguration)
    end

    it 'creates new instance when all required arguments are provided' do
      expect(described_class.new(api_key: 'key', subdomain: 'subdomain')).to be_kind_of(described_class)
    end
  end

  describe '#jobs' do
    let(:client){ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it 'returns array of posted jobs' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs?phase=published")
        .with(headers: { 'Authorization'=>'Bearer test', 'User-Agent'=>'Workable Ruby Client' })
        .to_return(status: 200, body: jobs_index_json_fixture, headers: {})

      expect(client.jobs).to be_kind_of(Array)
    end

    it 'raises exception on not authorized error (401)' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs?phase=published")
        .to_return(status: 401, body: '{"error":"Not authorized"}', headers: {})

      expect { client.jobs }.to raise_error(Workable::Errors::NotAuthorized)
    end

    it 'raises exception when status code differs from 200' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs?phase=published")
        .to_return(status: 500, body: '', headers: {})

       expect { client.jobs }.to raise_error(Workable::Errors::InvalidResponse)
    end
  end

  describe '#job_details' do
    let(:client){ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it 'returns details of given job' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs/03FF356C8B")
        .to_return(status: 200, body: job_json_fixture, headers: {})

      expect(client.job_details('03FF356C8B')).to be_kind_of(Workable::Job)
    end

    it 'raises an exception when job is not found' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs/invalid")
        .to_return(status: 404, body: '{"error":"Not found"}', headers: {})

      expect { client.job_details('invalid') }.to raise_error(Workable::Errors::NotFound)
    end
  end

  describe '#candidates' do
    let(:client){ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it 'returns array of candidates for given job' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs/03FF356C8B/candidates")
        .to_return(status: 200, body: job_candidates_json_fixture, headers: {})

      expect(client.job_candidates('03FF356C8B')).to be_kind_of(Array)
    end
  end

end
