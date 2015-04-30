require 'spec_helper'

describe Workable::Client do

  describe '#new' do
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

      expect(client.job_details('03FF356C8B')).to be_kind_of(Hash)
    end

    it 'raises an exception when job is not found' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs/invalid")
        .to_return(status: 404, body: '{"error":"Not found"}', headers: {})

      expect { client.job_details('invalid') }.to raise_error(Workable::Errors::NotFound)
    end
  end

  describe '#job_questions' do
    let(:client){ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it 'returns questions for given job' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs/03FF356C8B/questions")
        .to_return(status: 200, body: job_questions_json_fixture, headers: {})

      expect(client.job_questions('03FF356C8B')).to be_kind_of(Array)
    end

  end

  describe "#build_job_candidates_url" do
    subject{ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it "builds url without options" do
      expect(subject.send(:build_job_candidates_url, "test", {})).to eq("jobs/test/candidates")
    end

    it "builds url with multiple unknown options" do
      expect(subject.send(:build_job_candidates_url, "test", {:a => 1, :b =>1})).to eq("jobs/test/candidates?a=1&b=1")
    end

    it "builds url with limit" do
      expect(subject.send(:build_job_candidates_url, "test", {:limit => 100})).to eq("jobs/test/candidates?limit=100")
    end

    it "builds url with stage slug" do
      expect(subject.send(:build_job_candidates_url, "test", {:stage => "sourced"})).to eq("jobs/test/sourced/candidates")
    end

    it "builds url with stage slug and limit" do
      expect(subject.send(:build_job_candidates_url, "test", {:limit => 100, :stage => "sourced"})).to eq("jobs/test/sourced/candidates?limit=100")
    end
  end

  describe '#job_candidates' do
    let(:client){ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it 'returns array of candidates for given job' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs/03FF356C8B/candidates")
        .to_return(status: 200, body: job_candidates_json_fixture, headers: {})

      expect(client.job_candidates('03FF356C8B')).to be_kind_of(Array)
    end

    it 'raises exception on to long requests' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/jobs?phase=published")
        .to_return(status: 503, body: '{"error":"Not authorized"}', headers: {})

      expect { client.jobs }.to raise_error(Workable::Errors::RequestToLong)
    end

  end

  describe '#stages' do
    let(:client){ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it 'returns array of stages' do
      stub_request(:get, "https://www.workable.com/spi/v2/accounts/subdomain/stages")
        .to_return(status: 200, body: stages_json_fixture, headers: {})

      expect(client.stages).to be_kind_of(Array)
    end
  end

  describe "#transform_to" do
    let(:client){
      described_class.new(
        api_key: 'test',
        subdomain: 'subdomain',
        transform_to: {
          candidate: OpenStruct.method(:new)
        }
      )
    }

    it "transforms candidate" do
      result = client.send(:transform_to, :candidate, {:name => "Tom"})
      expect(result).to be_kind_of(OpenStruct)
      expect(result.name).to eq("Tom")
    end
  end

  describe "#transform_from" do
    let(:client){
      described_class.new(
        api_key: 'test',
        subdomain: 'subdomain',
        transform_from: {
          candidate: lambda { |input| input.marshal_dump }
        }
      )
    }

    it "transforms candidate" do
      input = client.send(:transform_from, :candidate, OpenStruct.new({:name => "Tom"}))
      expect(input).to be_kind_of(Hash)
      expect(input[:name]).to eq("Tom")
    end
  end

  describe "#transform" do
    let(:client){ described_class.new(api_key: 'test', subdomain: 'subdomain') }

    it "transforms one" do
      result = client.send(:transform, OpenStruct.method(:new), {:name => "Tom"})
      expect(result).to be_kind_of(OpenStruct)
      expect(result.name).to eq("Tom")
    end

    it "transforms many" do
      data = client.send(:transform, OpenStruct.method(:new), [{:name => "Tom"}, {:name => "Alice"}])
      expect(data).to be_kind_of(Array)
      expect(data.map(&:class)).to eq([OpenStruct, OpenStruct])
    end

    it "does not transform nil" do
      data = client.send(:transform, OpenStruct.method(:new), nil)
      expect(data).to eq(nil)
    end

    it "does not transform without transformation" do
      data = client.send(:transform, nil, OpenStruct.new({:slug => "sourced"}))
      expect(data).to eq(OpenStruct.new({:slug => "sourced"}))
    end
  end

end
