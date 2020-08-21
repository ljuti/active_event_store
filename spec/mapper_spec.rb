# frozen_string_literal: true

require "rails_helper"

describe ActiveEventStore::Mapper do
  let(:event_class) { ActiveEventStore::TestEvent }

  let(:event) { event_class.new(user_id: 1, action_type: "test", metadata: {timestamp: 321}) }
  let(:mapping) { ActiveEventStore::Mapping.new }

  subject { described_class.new(mapping: mapping) }

  describe "#event_to_serialized_record" do
    it "works", :aggregate_failures do
      record = subject.event_to_serialized_record(event)

      expect(record.event_type).to eq "test_event"
      expect(record.data).to eq({user_id: 1, action_type: "test"}.to_json)
      expect(record.metadata).to eq({timestamp: 321}.to_json)
      expect(record.event_id).to eq event.message_id
    end

    specify "with sync attributes" do
      event = event_class.new(user_id: 1, user: {name: "Sara"}, action_type: "test", metadata: {timestamp: 321})

      record = subject.event_to_serialized_record(event)
      expect(record.data).to eq({user_id: 1, action_type: "test"}.to_json)
    end

    it "registers an event type if it isn't registered beforehand" do
      expect(subject.send(:mapping).send(:data)).to be_empty

      subject.event_to_serialized_record(event)

      mapping = subject.send(:mapping).send(:data)

      expect(mapping).not_to be_empty
      expect(mapping).to have_key("test_event")
      expect(mapping.fetch("test_event")).to eq event_class.to_s
    end

    # TODO: This belongs to mapping spec
    it "should check if the mapping exists" do
      expect(subject.send(:mapping)).to receive(:exist?).with("test_event").once
      subject.event_to_serialized_record(event)
    end
  end

  describe "#serialized_record_to_event" do
    let(:record) { subject.event_to_serialized_record(event) }

    it "works", :aggregate_failures do
      new_event = subject.serialized_record_to_event(record)

      expect(new_event).to eq event
    end

    it "raises error if unknown event type" do
      mapper = described_class.new(mapping: ActiveEventStore::Mapping.new)

      expect { mapper.serialized_record_to_event(record) }
        .to raise_error(ArgumentError, /don't know how to deserialize event: "test_event"/i)

      expect { mapper.serialized_record_to_event(record) }
        .to raise_error(ArgumentError, /ActiveEventStore.mapper.register "test_event"/)
    end

    it "works if mapping is added explicitly" do
      mapper = described_class.new(mapping: mapping)

      mapping.register "test_event", "ActiveEventStore::TestEvent"

      new_event = mapper.serialized_record_to_event(record)
      expect(new_event).to eq event
    end

    describe "Metadata" do
      let(:event_with_metadata) { event_class.new(user_id: 1, action_type: "test", metadata: {timestamp: 321}) }
      let(:event_without_metadata) { event_class.new(user_id: 1, action_type: "test") }

      it "adds metadata if that's included" do
        record = subject.event_to_serialized_record(event_with_metadata)
        new_event = subject.serialized_record_to_event(record)

        expect(new_event).to eq event_with_metadata
        expect(new_event.metadata).not_to be_empty
      end

      it "doesn't add metadata if that's not included" do
        record = subject.event_to_serialized_record(event_without_metadata)
        new_event = subject.serialized_record_to_event(record)

        expect(new_event).to eq event_without_metadata
        expect(new_event.metadata).to be_empty
      end
    end
  end
end

RSpec.describe ActiveEventStore::Mapping do
  describe "#exist?" do
    let(:empty_mapping) { described_class.new }

    context "No mapping" do
      it "checks if mapping exists" do
        expect(empty_mapping.send(:data)).to receive(:key?).with("test_event").once
        empty_mapping.exist?("test_event")
      end

      it "" do
        expect(empty_mapping.exist?("test_event")).to be false
      end
    end

    context "Mapping exists" do
      it "" do
        mapping = described_class.new
        expect(mapping.register("test_event", "ActiveEventStore::TestEvent")).to eql("ActiveEventStore::TestEvent")
        expect(mapping.exist?("test_event")).to be true
      end
    end
  end

  describe "#register(type, class_name)" do
    it "registers a mapping for an event" do
      mapping = described_class.new
      expect(mapping.register("test_event", "ActiveEventStore::TestEvent")).to be_truthy

      expect(mapping.exist?("test_event")).to be true
      expect(mapping.fetch("test_event")).to eq "ActiveEventStore::TestEvent"

      expect(mapping.send(:data)).to have_key("test_event")
    end

    it "does not raise errors on valid inupt" do
      mapping = described_class.new
      expect { mapping.register("test_event", "ActiveEventStore::TestEvent") }
        .not_to raise_error
    end

    it "fails to register if no event provided" do
      mapping = described_class.new
      expect { mapping.register("test_event", nil) }
        .to raise_error(ArgumentError, /a defined ActiveEventStore::Event/)
    end

    it "fails to register if an event type is not provided" do
      mapping = described_class.new
      expect { mapping.register(nil, "ActiveEventStore::Event") }
        .to raise_error(ArgumentError, /an event type/)
    end
  end

  describe "#register_event(event_class)" do
    let(:event_class) { ActiveEventStore::TestEvent }
    
    it "registers an event and a subscriber" do
      mapping = described_class.new
      expect(mapping.register_event(event_class)).to be_truthy
    end

    it "uses event class properties to register" do
      mapping = described_class.new
      expect(mapping).to receive(:register).with("test_event", "ActiveEventStore::TestEvent")
      mapping.register_event(event_class)
    end

    it "does not raise errors when event class has required properties" do
      mapping = described_class.new
      expect { mapping.register_event(event_class) }
        .not_to raise_error
    end

    it "raises errors when the event class is something else" do
      klass = double(identifier: "foo", name: nil)
      mapping = described_class.new
      expect { mapping.register_event(klass) }
        .to raise_error(ArgumentError)
    end

    it "gets properties from event class for registration" do
      klass = double(ActiveEventStore::Event, identifier: "foo", name: "ActiveEventStore::Event")
      expect(klass).to receive(:identifier)
      expect(klass).to receive(:name)

      mapping = described_class.new
      expect(mapping).to receive(:register).with("foo", "ActiveEventStore::Event")
      mapping.register_event(klass)
    end

    it "returns the mapping when registering the mapping" do
      mapping = described_class.new
      expect(mapping.register_event(ActiveEventStore::TestEvent)).to eq "ActiveEventStore::TestEvent"
    end
  end
end