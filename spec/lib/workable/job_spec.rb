require 'spec_helper'

describe Workable::Job do
  it 'parses json response' do
    job = described_class.new(JSON.parse(job_json_fixture))

    expect(job.location.country_code).to eq 'PL'
    expect(job.created_at).to be_kind_of(Date)
  end
end
