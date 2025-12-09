# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Source
      class Base
        def initialize(**options)
          @options = options
        end

        def each(batch_size:, start_id: nil, &block)
          raise NotImplementedError, "Subclasses must implement #each"
        end

        def close
          # Override in subclasses if cleanup is needed
        end

        def to_json(*args)
          @options.to_json(*args)
        end

        protected

        attr_reader :options
      end
    end
  end
end
