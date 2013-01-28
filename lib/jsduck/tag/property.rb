require "jsduck/tag/tag"
require "jsduck/doc/subproperties"

module JsDuck::Tag
  class Property < Tag
    def initialize
      @pattern = "property"
      @key = :property
      @member_type = :property
    end

    # @property {Type} [name=default] ...
    def parse_doc(p)
      tag = p.standard_tag({:tagname => :property, :type => true, :name => true})
      tag[:doc] = :multiline
      tag
    end

    def process_doc(h, tags, pos)
      p = tags[0]
      h[:name] = p[:name]
      # Type might also come from @type, don't overwrite it with nil.
      h[:type] = p[:type] if p[:type]
      h[:default] = p[:default]
      h[:properties] = JsDuck::Doc::Subproperties.nest(tags, pos)[0][:properties]
      # Documentation after the first @property is part of the top-level docs.
      h[:doc] += p[:doc]
    end
  end
end