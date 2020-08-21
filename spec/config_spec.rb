# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveEventStore::Config do
  describe "#repository" do
    it "returns the event repository" do
      konfig = described_class.new
      expect(konfig.repository).to be_instance_of RailsEventStoreActiveRecord::EventRepository
    end
  end

  describe "#job_queue_name" do
    it "returns the queue name" do
      konfig = described_class.new
      expect(konfig.job_queue_name).to be_a Symbol
      expect(konfig.job_queue_name).to eq :events_subscribers
    end
  end

  describe "#store_options" do
    it "returns a hash of options" do
      konfig = described_class.new
      expect(konfig.store_options).to be_instance_of Hash
    end
  end
end