module ApiPresenter
  module Resolvers
    # Handles loading of associated collections and policies, or counts,
    # for the given collection or single record.
    class IncludedCollectionsResolver < Resolvers::Base

      attr_reader :resolved_collections

      delegate :associations_map, :included_collection_names, to: :presenter

      # @param presenter [ApiPresenter::Base]
      def initialize(presenter)
        super(presenter)
        preload if relation.is_a?(ActiveRecord::Relation) && resolved_associations_map.any?
      end

      def call
        resolve_collections
        self
      end

      private

      # ActiveRecord preload of included collections
      def preload
        presenter.preload(resolved_associations_map.flat_map {|k,v| v[:associations]})
      end

      # Whitelists included collections against classes that current_user is permitted to see and any specified conditions
      #
      # @param association_keys [Array]
      #
      # @return [Hash] Whitelisted copy of `associations_map`
      #
      def resolved_associations_map
        @resolved_associations_map ||= included_collection_names.inject({}) do |hash, included_collection_name|
          if resolve_collection?(included_collection_name)
            hash[included_collection_name] = { associations: associations_map[included_collection_name][:associations] }
          end
          hash
        end
      end

      def resolve_collection?(included_collection_name)
        associations_map[included_collection_name] &&
        collection_policy_permits?(included_collection_name) &&
        collection_condition_permits?(included_collection_name)
      end

      # Runs policy check to ensure current_user is allowed to view objects of the given type
      # TODO: configuration to allow pass if no policy defined, with configurable warning log
      def collection_policy_permits?(included_collection_name)
        Pundit.policy(current_user, included_collection_name.to_s.classify.constantize).index?
      end

      # Runs check on included association condition if present.
      #
      # Conditions can be either a string, which will be interpolated, or
      # a symbol, which will execute the corresponding method. Both
      # options must return a truthy result.
      #
      # @example String condition
      #   def associations_map
      #     {
      #       categories: { associations: :category, condition: 'current_user.admin?' }
      #     }
      #   }
      #
      # @example Method condition
      #   def associations_map
      #     {
      #       categories: { associations: :category, condition: :admin? }
      #     }
      #   }
      #
      # @return [Boolean]
      def collection_condition_permits?(included_collection_name)
        if (condition = associations_map[included_collection_name][:condition])
          if condition.is_a?(String)
            presenter.instance_eval(condition)
          elsif condition.is_a?(Symbol)
            presenter.send(condition)
          end
        else
          true
        end
      end

      # Map requested collections from relation
      def resolve_collections
        @resolved_collections = resolved_associations_map.inject({}) do |hash, (k,v)|
          collection_records = []
          collection_associations = Array.wrap(v[:associations])
          collection_associations.each do |association|
            add_records_from_collection_association(relation, association, collection_records)
          end
          collection_records.flatten!
          collection_records.compact!
          collection_records.uniq!
          hash[k] = collection_records
          hash
        end
      end

      # Recursive method that traverses n-nested associations to get at the requested records
      #
      # @param current_relation   [ActiveRecord::Relation]  Original relation or nested association, changes during recursion
      # @param association        [Symbol, Hash]            Source association key or nested hash association
      # @param collection_records [Array]                   Concatenated included collection records
      #
      def add_records_from_collection_association(current_relation, association, collection_records)
        if association.is_a?(Hash)
          association.each do |k,v|
            nested_association = current_relation.flat_map { |record| record.send(k) }.compact.uniq
            Array.wrap(v).each do |nested_association_association|
              add_records_from_collection_association(nested_association, nested_association_association, collection_records)
            end
          end
        else
          collection_records << current_relation.map { |record| record.send(association) }
        end
      end
    end
  end
end
