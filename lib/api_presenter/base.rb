module ApiPresenter
  class Base

    attr_reader :current_user, :params, :relation

    # @example
    #   @presenter = PostPresenter.call(
    #     current_user: current_user,
    #     relation:     relation,
    #     params:       params
    #   )
    #
    # @param (see #initialize)
    #
    # @return [ApiPresenter::Base]
    #
    def self.call(**kwargs)
      new(kwargs).call
    end

    # @param current_user [User]                          Optional. current_user context.
    # @param relation     [ActiveRecord::Relation, Array] Relation or array-wrapped record(s) to present
    # @param params       [Hash]                          Controller params
    # @option params      [Boolean]       :count          Optional. If true, return count only.
    # @option params      [String, Array] :include        Optional. Associated resources to include.
    # @option params      [Boolean]       :policies       Optional. If true, resolve polciies for relation.
    #
    def initialize(current_user: nil, relation:, params: {})
      @current_user = current_user
      @relation     = relation
      @params       = params
    end

    # @return [ApiPresenter::Base]
    #
    def call
      return self if count_only?
      initialize_resolvers
      call_resolvers
      self
    end

    # Primary collection, empty if count requested
    #
    # @return [ActiveRecord::Relation, Array<ActiveRecord::Base>]
    #
    def collection
      count_only? ? [] : relation
    end

    # Count of primary collection
    #
    # @note Delegate to Kaminari's `total_count` property, or regular count if not a paginated relation
    #
    # @return [Integer]
    #
    def total_count
      relation.respond_to?(:total_count) ? relation.total_count : relation.count
    end

    # Policies for the primary collection
    #
    # @example
    #   [
    #     { post_id: 1, update: true, destroy: true },
    #     { post_id: 2, update: false, destroy: false }
    #   ]
    #
    # @return [<Array<Hash>]
    #
    def policies
      @policies_resolver ? @policies_resolver.resolved_policies : {}
    end

    # Class names of included collections
    #
    # @example
    #   [:categories, :sub_categories, :users]
    #
    # @return [Array<Symbol>]
    #
    def included_collection_names
      @included_collection_names ||= Parsers::ParseIncludeParams.call(params[:include])
    end

    # Map of included collection names and loaded record
    #
    # @example
    #   {
    #     categories:     [#<Category id:1>],
    #     sub_categories: [#<SubCategory id:1>],
    #     users:          [#<User id:1>, #<User id:2]
    #   }
    #
    # @return [Hash]
    #
    def included_collections
      @included_collections_resolver ? @included_collections_resolver.resolved_collections : {}
    end

    # Preload additional records with the relation
    #
    # @note Called by resolvers, but can also be called if additional data is required that does
    #   not need to be loaded as an included collection, and for some reason cannot be chained
    #   onto the original relation.
    #
    # @param associations [Symbol, Array<Symbol>]
    #
    def preload(associations)
      @relation = @relation.preload(associations)
    end

    # Hash map that defines the sources for included collection names
    #
    # @example
    #   def associations_map
    #     {
    #       categories:     { associations: { sub_category: :category } },
    #       sub_categories: { associations: :sub_category },
    #       users:          { associations: [:creator, :publisher] }
    #     }
    #   end
    #
    # @abstract
    #
    # @return [Hash]
    #
    def associations_map
      {}
    end

    # Policy methods to resolve for the primary relation
    #
    # @example Single
    #   def policy_methods
    #     :update
    #   end
    #
    # @example Multiple
    #   def policy_methods
    #     [:update, :destroy]
    #   end
    #
    # @abstract
    #
    # @return [Symbol, Array<Symbol>]
    #
    def policy_methods
      []
    end

    # Policy associations to preload to optimize policy resolution
    #
    # @example Single
    #   def policy_associations
    #     :user_profile
    #   end
    #
    # @example Multiple
    #   def policy_associations
    #     [:user_profile, :company]
    #   end
    #
    # @abstract
    #
    # @return [Symbol, Array<Symbol>]
    #
    def policy_associations
      []
    end

    private

    def count_only?
      @count_only ||= !!params[:count]
    end

    def resolve_policies?
      @resolve_policies ||= current_user && !!params[:policies]
    end

    def resolve_included_collctions?
      included_collection_names.any?
    end

    def initialize_resolvers
      @policies_resolver              = Resolvers::PoliciesResolver.new(self) if resolve_policies?
      @included_collections_resolver  = Resolvers::IncludedCollectionsResolver.new(self) if resolve_included_collctions?
    end

    def call_resolvers
      @policies_resolver.call if @policies_resolver
      @included_collections_resolver.call if @included_collections_resolver
    end
  end
end
