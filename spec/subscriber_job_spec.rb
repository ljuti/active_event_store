# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveEventStore::SubscriberJob, type: :job do
  class EventHandler
  end

  include ActiveJob::TestHelper

  before do
    ActiveEventStore.mapping.register "test_event", "EventHandler"
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  let(:event) { ActiveEventStore::TestEvent.new(user_id: 1) }
  let(:payload) do
    {
      event_type: event.event_type,
      event_id: event.event_id,
      data: event.data.to_json,
      metadata: {}
    }
  end

  subject(:job) { described_class.perform_later(payload) }

  it "queues the job" do
    expect { job }
      .to have_enqueued_job(described_class)
  end

  it "executes perform" do
    expect(described_class).to receive(:perform).with(payload)
    perform_enqueued_jobs { job }
  end
end