require "spec_helper"
require "active_support/core_ext/numeric/bytes"
require "max_memory_quota_calculator"

describe Couchbase::MaxMemoryQuotaCalculator do
  describe ".from_node" do
    let(:calculator) { described_class.from_node(node) }

    context "a Linux node" do
      let :node do
        {
          "memory" => {
            "total" => "1733252kB",
          },
        }
      end

      it { calculator.should be_a_kind_of(described_class) }

      it "initializes the calculator with the node's memory total" do
        calculator.total_in_bytes.should == 1_774_850_048
      end
    end
  end

  describe "#total_in_bytes" do
    it "uses the initialized value" do
      total = rand(32).gigabytes
      described_class.new(total).total_in_bytes.should == total
    end
  end

  describe "#in_megabytes" do
    it "is 819MB for 1GB, using the max 80% rule" do
      described_class.new(1.gigabyte).in_megabytes.should eql(819)
    end

    it "is 7GB for 8GB, using the max minus 1GB rule" do
      described_class.new(8.gigabytes).in_megabytes.should eql(7.gigabytes / 1024 / 1024)
    end
  end
end
