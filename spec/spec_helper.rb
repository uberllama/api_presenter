$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_record'
require 'api_presenter'

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :categories do |t|
    t.string :name
  end

  create_table :sub_categories do |t|
    t.integer :category_id
    t.string :name
  end

  create_table :posts do |t|
    t.integer :sub_category_id
    t.integer :creator_id
    t.integer :publisher_id
    t.boolean :published
    t.text :body
  end

  create_table :users do |t|
    t.string :name
  end
end

class Category < ActiveRecord::Base
  has_many :sub_categories
  has_many :posts, through: :sub_categories
end

class SubCategory < ActiveRecord::Base
  belongs_to :category
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :sub_category
  belongs_to :creator, class_name: 'User'
  belongs_to :publisher, class_name: 'User'
end

class User < ActiveRecord::Base
  has_many :created_posts, class_name: 'Post', foreign_key: 'creator_id'
  has_many :published_posts, class_name: 'Post', foreign_key: 'publisher_id'
end

class PostPresenter < ApiPresenter::Base; end

class PostQuery
  def self.records
    Post.all
  end
end

class PostsController
  include ApiPresenter::Concerns::Presentable

  attr_reader :current_user, :params

  def initialize(current_user, params)
    @current_user = current_user
    @params       = params
  end

  def index
    records = PostQuery.records
    present(records)
  end

  def show
    record = Post.find(params[:id])
    present(record)
  end
end
