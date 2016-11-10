module ApiPresenter
  module Generators
    class PresenterGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __FILE__)

      def create_application_presenter
        unless File.exist?('app/presenters/application_api_presenter.rb')
          copy_file('application_presenter.rb', 'app/presenters/application_api_presenter.rb')
        end
      end

      def create_presenter
        template('presenter.rb', File.join('app/presenters', class_path, "#{file_name}_presenter.rb"))
      end
    end
  end
end
