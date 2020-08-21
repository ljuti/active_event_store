# frozen_string_literal: true

module ActiveEventStore
  class Mapping
    delegate :fetch, to: :data

    def initialize
      @data = {}
    end

    def register(type, class_name)
      raise ArgumentError.new("You must provide an event type as a string") unless type.is_a?(String)
      raise ArgumentError.new("You must provide a defined ActiveEventStore::Event class") unless !!class_name && Object.const_defined?(class_name)
      data[type] = class_name
    end

    def register_event(event_class)
      register event_class.identifier, event_class.name
    end

    def exist?(type)
      data.key?(type)
    end

    private

    attr_reader :data
  end
end
