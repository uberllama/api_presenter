require 'active_support/concern'

module ApiPresenter
  module Concerns
    module Presentable
      extend ActiveSupport::Concern

      private

      # Instantiates presenter for the given relation, array of records, or single record
      #
      # @example Request with included records
      #   GET /api/posts?include=categories,subCategories,users
      #
      # @example Request with policies
      #   GET /api/posts?policies=true
      #
      # @example Request with included records and policies
      #   GET /api/posts?include=categories,subCategories,users&policies=true
      #
      # @example Request with count only
      #   GET /api/posts?count=true
      #
      # @example PostsController
      #   include ApiPresenter::Concerns::Presentable
      #
      #   def index
      #     posts = Post.page
      #     present posts
      #   end
      #
      #   def show
      #     @post = Post.find(params[:id])
      #     present @post
      #   end
      #
      # @param relation_or_record [ActiveRecord::Relation, Array<ActiveRecord::Base>, ActiveRecord::Base]
      #
      def present(relation_or_record)
        klass, relation = if relation_or_record.is_a?(ActiveRecord::Relation)
          [relation_or_record.klass, relation_or_record]
        else
          record_array = Array.wrap(relation_or_record)
          [record_array.first.class, record_array]
        end

        @presenter = presenter_klass(klass).call(
          current_user: defined?(current_user) ? current_user : nil,
          relation:     relation,
          params:       params
        )
      end

      # Progressive search for klass's Presenter
      def presenter_klass(klass)
        "#{klass.name}Presenter".safe_constantize ||
        "#{klass.base_class.name}Presenter".safe_constantize ||
        ApiPresenter::Base
      end

    end
  end
end
