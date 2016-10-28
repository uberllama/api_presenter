module ApiPresenter

  # Parses values into array of acceptable association map keys:
  # * Removes blanks and dups
  # * Underscores camel-cased keys
  # * Converts to symbol
  #
  # @param values [String, Array<String>, Array<Symbol>] Comma-delimited string or array
  #
  # @return [Array<Symbol>]
  #
  class ParseIncludeParams
    def self.call(values)
      return [] if values.blank?

      array = values.is_a?(Array) ? values.dup : values.split(',')
      array.select!(&:present?)
      array.map! { |value| value.try(:underscore) || value }
      array.uniq!
      array.map!(&:to_sym)

      array
    end
  end
end
