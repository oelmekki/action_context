module ActionContext
  module Helpers
    # Format errors for display.
    # Resource may be a model or an handler - just anything including ActiveModel::Validations
    #
    # @param resource [Object] the source of errors
    # @option use_id [Boolean] true to use `#error-explanation` as block id, will use a class instead else
    # @option field [Symbol|String] the field to generate errors from (default: all)
    # @option opts [Hash] other attributes to pass to block
    # @return [String] the error html
    def error_messages_for_handler( resource, use_id: true, field: nil, **opts )
      attributes = {}

      if use_id
        attributes[ :id ] = 'error-explanation'
      else
        attributes[ :class ] = 'error-explanation'
        attributes[ :class ] = "#{attributes[ :class ]} #{classes}" if ( classes = opts.delete( :class ) )
      end

      content_tag( :ul, attributes.merge( opts ) ) do
        if field
          resource.errors[ field ].map { |msg| "<li>#{msg}</li>" }.join( "\n" ).html_safe
        else
          resource.errors.full_messages.map { |msg| content_tag( :li, msg ) }.join( "\n" ).html_safe
        end
      end
    end
  end
end
