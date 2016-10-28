require 'active_support/core_ext/module'

module ApiPresenter
  module Resolvers
    class Base

      attr_reader :presenter

      delegate :current_user, :relation, to: :presenter

      def initialize(presenter)
        @presenter = presenter
      end
    end
  end
end
