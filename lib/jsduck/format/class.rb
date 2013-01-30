require 'jsduck/type_parser'
require 'jsduck/logger'
require 'jsduck/tag_registry'
require 'jsduck/format/shortener'
require 'jsduck/util/html'

module JsDuck
  module Format

    # Converts :doc properties of class from markdown to HTML, resolves
    # @links, and converts type definitions to HTML.
    class Class
      # Set to false to disable HTML-formatting of type definitions.
      attr_accessor :include_types

      def initialize(relations, formatter)
        @relations = relations
        @formatter = formatter
        @include_types = true
      end

      # Runs the formatter on doc object of a class.
      # Accessed using Class#internal_doc
      def format(cls)
        @cls = cls
        @formatter.class_context = cls[:name]
        @formatter.doc_context = cls[:files][0]
        format_tags(cls)
        # format all members (except hidden ones)
        cls[:members] = cls[:members].map {|m| m[:hide] ? m : format_member(m)  }
        cls
      end

      # Access to the Img::DirSet object inside doc-formatter
      def images
        @formatter.images
      end

      private

      def format_member(m)
        @formatter.doc_context = m[:files][0]
        format_tags(m)
        if expandable?(m) || Format::Shortener.too_long?(m[:doc])
          m[:shortDoc] = Format::Shortener.shorten(m[:doc])
        end

        # We don't validate and format CSS var and mixin type definitions
        is_css_tag = m[:tagname] == :css_var || m[:tagname] == :css_mixin

        m[:html_type] = (@include_types && !is_css_tag) ? format_type(m[:type]) : m[:type] if m[:type]
        m[:params] = m[:params].map {|p| format_item(p, is_css_tag) } if m[:params]
        m[:return] = format_item(m[:return], is_css_tag) if m[:return]
        m[:throws] = m[:throws].map {|t| format_item(t, is_css_tag) } if m[:throws]
        m[:properties] = m[:properties].map {|b| format_item(b, is_css_tag) } if m[:properties]
        m
      end

      def expandable?(m)
        m[:params] || (m[:properties] && m[:properties].length > 0) || m[:default] || m[:deprecated] || m[:template]
      end

      def format_item(it, is_css_tag)
        it[:doc] = @formatter.format(it[:doc]) if it[:doc]
        it[:html_type] = (@include_types && !is_css_tag) ? format_type(it[:type]) : it[:type] if it[:type]
        it[:properties] = it[:properties].map {|s| format_item(s, is_css_tag) } if it[:properties]
        it
      end

      def format_type(type)
        tp = TypeParser.new(@relations, @formatter)
        if tp.parse(type)
          tp.out
        else
          context = @formatter.doc_context
          if tp.error == :syntax
            Logger.warn(:type_syntax, "Incorrect type syntax #{type}", context[:filename], context[:linenr])
          else
            Logger.warn(:type_name, "Unknown type #{type}", context[:filename], context[:linenr])
          end
          Util::HTML.escape(type)
        end
      end

      def format_tags(context)
        TagRegistry.html_renderers.each do |tag|
          if context[tag.key]
            tag.format(context, @formatter)
          end
        end
      end

    end

  end
end
