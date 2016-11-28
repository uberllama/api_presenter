# ApiPresenter

REST APIs provide a consice and conventional means of retreiving resources for a client. But in the real world, clients often have addiitonal data requirements beyond the specifically requested resource(s):

1. Current user permissions for the returned records, so that the client can intelligently draw its UI (ex: edit/delete buttons).
2. Associated data, to mitigate total number of requests (ex: return authors with posts).

ApiPresenter provides both of these things, plus a bit more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'api_presenter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install api_presenter

## Usage

ApiPresenter is well suited to large, relational systems. We'll use a blog as the usage example for this gem. The blog has the following model structure:

```ruby
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
```

Usage examples will be in the context of requesting posts as the primary collection.

### 0. Generate config file

`rails g api_presenter:config`

Generate your configuration file. Currently, ApiPresenter allows allows customization of querysting parameter names for including policies and associated resources (see below). More configuration options to come.

### 1. Create your Presenter

Generate a presenter class for your ActiveRecord model. The generator will also ensure the presence of an `ApplicationApiPresenter` base class for centralized methods.

`rails g api_presenter:presenter post`

```ruby
class PostPresenter < ApplicationApiPresenter
  def associations_map
    {
      categories:     { associations: { sub_category: :category } },
      sub_categories: { associations: :sub_category },
      users:          { associations: [:creator, :publisher] }
    }
  end

  def policy_methods
    [:update, :destroy]
  end

  # def policy_associations
  #   :user_profile
  # end
end
```

Presenters can define three opt-in methods:

* `associations_map` Associated resources that you would like to be includable with the primary collection. Consists of the model name as key and the traversal required to preload/load them. In most cases, the value of `associations` will correspond directly to associations on the primary model.
* `policy_methods` A list of Pundit policy methods to resolve for the primary collection if policies are requested.
* `policy_associations` Additional associations to preload in order to optimize policies that must traverse asscoiations.

### 2. Enable your controllers

Include the supplied controller concern at your `ApplicationController` level, or on a specific controller. This concern provides the `present` method, which can be called on an `ActiveRecord::Relation`, an array of records, or even a single record (preloading of associated collections is only performed for relations). 

```ruby
class ApplicationController
  include ApiPresenter::Concerns::Presentable
end

class PostsController < ApplicationController

  # @example
  #   GET /posts?include=categories,subCategories,users&policies=true
  #
  def index
    authorize Post
    posts = PostQuery.records(current_user, params)
    present posts
  end

  # @example
  #   GET /posts/:id?include=categories,subCategories,users&policies=true
  #
  def show
    @post = Post.find(params[:id])
    authorize @post
    present @post
  end
end
```

Controller params are used to tell the presenter what to load. The default param keys are `count`, `policies`, and `include`:

* `count [Boolean]` Pass true if you just want a count of the primary collection.
* `policies [Boolean]` Pass true if you want to resolve policies for the primary collection.
* `include [String, Array]` A comma-delimited list or array of collection names (camelCase or under_scored) to include with the primary collection.

### 3. Render the result

After calling the `present` method in a controller action, you access your processed collection through the `@presenter` instance variable. How you ultimately render the data produced by ApiPresenter is up to you. 

`@presenter` has the following properties:

* `collection [Array<ActiveRecord::Base>]` The primary collection that was passed into the presenter. Empty if count requested.
* `total_count [Integer]` When using Kaminari or another pagination method that defines a `total_count` property, returns unpaginated count. If the primary collection is not an `ActiveRecord::Relation`, simply returns the number of records.
* `included_collection_names [Array<Symbol>]` Convenience method that returns an array of included collecton model names.
* `included_collections [Hash]` A hash of included collections, consisting of the model name and corresponding records.
* `policies [Array<Hash>]` An array of resolved policies for the primary collection.

Here's an example of how you might render your data using JBduiler:

### api/posts/index.json.jbuilder

```ruby
json.posts(@presenter.collection) do |post|
  json.partial!(post)
end
json.partial!("api/shared/included_collections_and_meta", presenter: @presenter)
```

### api/posts/show.json.jbuilder

```ruby
json.post do
  json.partial!(@post)
end
json.partial!("api/shared/included_collections_and_meta", presenter: @presenter)
```

### api/shared/included_collections_and_meta

```ruby
presenter.included_collections.each do |collection_key, collection|
  json.set!(collection_key, collection) do |record|
    json.partial!(record)
  end
end

json.meta do
  json.total_count(presenter.total_count)
  json.policies presenter.policies
end
```

### 4. Output

Using the code above, our call to `GET /posts` would result in the following JSON:

```json
{
  "posts": [
    { "id": 1, "sub_category": 1, "creator_id": 1, "publisher_id": 2, "body": "Lorem dim sum", "published": true },
    { "id": 2, "sub_category": 2, "creator_id": 3, "publisher_id": null, "body": "Lorem dim sum", "published": false }
  ],
  "categories": [
    { "id": 1, "name": "Animals" }
  ],
  "sub_categories": [
    { "id": 1, "category_id": 1, "name": "Lemurs" },
    { "id": 2, "category_id": 1, "name": "Anteaters" }
  ],
  "users": [
    { "id": 1, "name": "Dora" },
    { "id": 2, "name": "Boots" },
    { "id": 3, "name": "Backpack" }
  ],
  "meta": {
    "total_count": 2,
    "policies": [
      { "post_id": 1, "update": true, "destroy": false },
      { "post_id": 2, "update": true, "destroy": true }
    ]
  }
}
```

And similarily, for `GET /posts/1`:

```json
{
  "post": { "id": 1, "sub_category": 1, "creator_id": 1, "publisher_id": 2, "body": "Lorem dim sum", "published": true },
  "categories": [
    { "id": 1, "name": "Animals" }
  ],
  "sub_categories": [
    { "id": 1, "category_id": 1, "name": "Lemurs" }
  ],
  "users": [
    { "id": 1, "name": "Dora" },
    { "id": 2, "name": "Boots" }
  ],
  "meta": {
    "total_count": 1,
    "policies": [
      { "post_id": 1, "update": true, "destroy": false }
    ]
  }
}
```

## Advanced Usage

### Conditional includes

There are a number of ways you can conditionally include resources, depending, for insatnce, on user type.

#### Add conditions inside `associations_map` method

```ruby
class PostPresenter < ApiApplicationPresenter
  def associations_map
    current_user.admin? ? admin_associations_map : user_associations_map
  end

  private

  def user_associations_map
    {
      sub_categories: { associations: :sub_category },
      users:          { associations: [:creator, :publisher] }
    }
  end

  def admin_associations_map
    {
      categories:     { associations: { sub_category: :category } },
      sub_categories: { associations: :sub_category },
      users:          { associations: [:creator, :publisher] }
    }
  end
end
```

#### Use `condition` property within `association_map` definition

##### Via inline string

```ruby
class PostPresenter < ApiPresenter::Base
  def associations_map
  {
    categories:     { associations: { sub_category: :category }, condition: 'current_user.admin?' },
    sub_categories: { associations: :sub_category },
    users:          { associations: [:creator, :publisher] }
  }
  end
end
```

##### Via method call

```ruby
class PostPresenter < ApiPresenter::Base
  def associations_map
  {
    categories:     { associations: { sub_category: :category }, condition: :admin? },
    sub_categories: { associations: :sub_category },
    users:          { associations: [:creator, :publisher] }
  }
  end

  private

  def admin?
    current_user.admin?
  end
end
```

#### Control it from your policy

```ruby
class CategoryPolicy < ApplicationPolicy
  def index?
    user.admin?
  end
end
```

## TODO

* Decouple from Pundit
* Make index policy checking on includes optional
* Allow custom collection names
* Add test helper to assert presenter was called for a given controller action

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/uberllama/api_presenter.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

