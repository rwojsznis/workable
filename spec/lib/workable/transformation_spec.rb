require 'spec_helper'

describe Workable::Transformation do
  let(:client){
    described_class.new(
      candidate: OpenStruct.method(:new)
    )
  }

  describe "transforming candidate" do
    it "transforms candidate" do
      result = client.apply(:candidate, {:name => "Tom"})
      expect(result).to be_kind_of(OpenStruct)
      expect(result.name).to eq("Tom")
    end
  end

  describe "transforming many candidates" do
    it "transforms many" do
      result = client.apply(:candidate, [{:name => "Tom"}, {:name => "Alice"}])
      expect(result).to be_kind_of(Array)
      expect(result.map(&:class)).to eq([OpenStruct, OpenStruct])
    end
  end

  describe "transforming nil" do
    it "does not transform nil" do
      expect(client.apply(:candidate, nil)).to eq(nil)
    end
  end

  describe "no transformation" do
    it "does not transform without transformation" do
      data = client.apply(:stage, {:slug => "sourced"})
      expect(data).to eq({:slug => "sourced"})
    end
  end
end
