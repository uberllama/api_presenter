# ApiPresenter

A much longer readme is coming, including best practices and cautions, but in the meantime lets keep it simple...

When creating RESTful APIs for web or mobile clients, there are a couple of common use cases that have emerged:

* Allow inclusion of associated data to mitigate number of requests
* Include permissions so that the client can intelligently draw its UI (ex: edit/delete buttons), while maintaining a single source of truth

ApiPresenter does both of these things, plus a bit more.

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

We'll use a simple blog as the usage example for this gem. The blog has the following model structure:

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

When clients request posts (the primary collection), they may want any or all of the above data for those posts.

### Create your Presenter

```ruby
class PostPresenter < ApiPresenter::Base
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

Presenters can define up to three methods:

* `associations_map` The includable resources for the ActiveRecord model (Post, in this case). Consists of the model name as key and traversla required to preload/load them. In most cases, the value of `associations` will correspond directly to associations on the primary model.
* `policy_methods` A list of Pundit policy methods to resolve for the primary collection.
* `policy_associations` Additional records to preload in order to optimize policies that must traverse asscoiations.

### Enable your controllers

ApiPresenter provides a controller concern that executes the Presenter. This process analyzes your params, preloads records as needed, and produces a `@presenter` object you can work with.

```ruby
class ApplicationController
  include ApiPresenter::Concerns::Presentable
end

class PostsCOntroller < ApplicationController
  def index
    posts = PostQuery.records(current_user, params)
    present posts
  end

  def show
    post = Post.find(params[:id])
    present post
  end
end
```

### Render the result

How you ultimately render the primary collection and the data produced by ApiPresenter is up to you. `@presenter` has the following properties:

* `collection` The primary collection that was passed into the presenter.
* `total_count` When using Kaminari or another pagination method that defines a `total_count` property, returns unpaginated count. If the primary collection is not an `ActiveRecord::Relation`, simply returns the number of records.
* `included_collection_names` Convenience method that returns an array of included collecton model names.
* `included_collections` A hash of included collections, consisting of the model name and corresponding records.
* `policies` An array of resolved policies for the primary collection.

Here's an example of how you might render this using JBduiler:

### api/posts/index.json.jbuilder

```ruby
json.posts(@presenter.collection) do |post|
  json.partial!(post)
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

## Advanced Usage

### Conditional includes

There are a number of ways you can conditionally include resources, depending, for insatnce, on user type.

#### Add conditions inside `associations_map` method

```ruby
class PostPresenter < ApiPresenter::Base
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

Via inline string:

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

Via method call:

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

* More doc
* Decouple from Pundit
* Make index policy checking on includes optional
* Allow custom collection names
* Add test helper to assert presenter was called for a given controller action

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/api_presenter.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

