# frozen_string_literal: true

module ActiveEventStore
  class TestEvent < ActiveEventStore::Event
    self.identifier = "test_event"

    attributes :user_id, :action_type

    sync_attributes :user
  end

  class AnotherTestEvent < TestEvent
  end
end

module OneModule
end

module OneModule
  class TestEvent < ActiveEventStore::Event
    self.identifier = "one_module.test_event"

    attributes :user_id, :action_type

    sync_attributes :user
  end
end