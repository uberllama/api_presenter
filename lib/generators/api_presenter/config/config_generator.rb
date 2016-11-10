module ApiPresenter
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def copy_config_file
        copy_file 'config.rb', 'config/initializers/api_presenter.rb'
      end
    end
  end
end
