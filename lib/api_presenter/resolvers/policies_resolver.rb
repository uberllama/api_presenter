module ApiPresenter
  module Resolvers
    class PoliciesResolver < Resolvers::Base

      attr_reader :presenter, :resolved_policies

      delegate :policy_associations, :policy_methods, to: :presenter

      # Optimally resolves designated policies for current_user and supplied records.
      #
      # Use where it is desirable for an API response to include permissions (policy)
      # metadata so that a client can correctly present resource actions.
      #
      # Initialize and preload policy associations for the given relation
      #
      # @param presenter [ApiPresenter::Base]
      def initialize(presenter)
        super(presenter)
        preload if relation.is_a?(ActiveRecord::Relation) && policy_associations.present?
      end

      # Resolves policies and combines them into an id-based hash
      #
      # @return [PolicyPresenter::Base]
      #
      def call
        resolve_policies
        self
      end

      private

      # Preload any associations required to optimize policy methods that traverse models
      def preload
        presenter.preload(policy_associations)
      end

      # Run policies for each record in the relation
      def resolve_policies
        @resolved_policies = relation.map do |record|
          policy_definition = Pundit.policy(current_user, record)
          record_policies = { :"#{id_attribute}" => record.id }
          Array.wrap(policy_methods).each do |policy_method|
            record_policies[policy_method] = policy_definition.send("#{policy_method}?")
          end
          record_policies
        end
      end

      # @example Post -> "post_id"
      #
      # @return [String]
      #
      def id_attribute
        @id_attribute ||= begin
          klass = if relation.is_a?(ActiveRecord::Relation)
            relation.klass
          else
            relation.first.class
          end
          "#{klass.base_class.name.underscore}_id"
        end
      end
    end
  end
end
