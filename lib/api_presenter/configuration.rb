module ApiPresenter
  class Configuration
    # Querystring param key that determines whether or not to just produce a total count
    #
    # @return [Symbol]
    #
    attr_accessor :count_param

    # Querystring param key containing the included collection names
    #
    # @return [Symbol]
    #
    attr_accessor :include_param

    # Querystring param key that determines whether or not to resolve policies for primary collection
    #
    # @return [Symbol]
    #
    attr_accessor :policies_param

    def initialize
      @count_param    = :count
      @include_param  = :include
      @policies_param = :policies
    end
  end

  # @return [ApiPresenter::Configuration] ApiPresenter's current configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Set ApiPresenter configuration
  #
  # @example
  #   ApiPresenter.configure do |config|
  #     config.include_param = :includes
  #   end
  #
  def self.configure
    yield configuration
  end
end
