module GraphQL::Relay::Walker
  class QueryBuilder
    DEFAULT_ARGUMENTS = { 'first' => 5 }.freeze
    BASE_QUERY = 'query($id: ID!) { node(id: $id) { id } }'.freeze

    attr_reader :schema, :connection_arguments, :ast, :except, :only

    # Initialize a new QueryBuilder.
    #
    # schema                - The GraphQL::Schema to build a query for.
    # connection_arguments: - A Hash or arguments to use for connection fields
    #                         (optional).
    #
    # Returns nothing.
    def initialize(schema, except: nil, only: nil, connection_arguments: DEFAULT_ARGUMENTS)
      @schema = schema
      @except = except
      @only   = only
      @connection_arguments = connection_arguments
      @ast = build_query
    end

    # Get the built query.
    #
    # Returns a String.
    def query_string
      ast.to_query_string
    end

    private

    # Build a query for our relay schema that selects an inline fragment for
    # every node type. For every inline fragment, we select the ID of every node
    # field and connection.
    #
    # Returns a GraphQL::Language::Nodes::Document instance.
    def build_query
      GraphQL.parse(BASE_QUERY).tap do |d_ast|
        selections = d_ast.definitions.first.selections.first.selections

        node_types.each do |type|
          selections << inline_fragment_ast(type) if include?(type)
        end

        selections.compact!
      end
    end

    # Private: Depending on the `except` or `include` filters,
    # should this item be included a AST of the given type.
    #
    # type           - The GraphQL item to identify to make the fragment
    #
    # Returns a Boolean.
    def include?(type)
      return !@except.call(type, {}) if @except
      return @only.call(type, {}) if @only
      true
    end

    # Make an inline fragment AST.
    #
    # type           - The GraphQL::ObjectType instance to make the fragment
    #                  for.
    # with_children: - Boolean. Whether to select all children of this inline
    #                  fragment, or just it's ID.
    #
    # Returns a GraphQL::Language::Nodes::InlineFragment instance or nil if the
    # created AST was invalid for having no selections.
    def inline_fragment_ast(type, with_children: true)
      selections = []
      if with_children
        type.all_fields.each do |field|
          field_type = field.type.unwrap
          if node_field?(field) && include?(field_type)
            selections << node_field_ast(field)
          elsif connection_field?(field) && include?(field_type)
            selections << connection_field_ast(field)
          end
        end
      elsif id = type.get_field('id')
        selections << field_ast(id)
      end

      selections.compact!

      if selections.none?
        nil
      else
        GraphQL::Language::Nodes::InlineFragment.new(
          type: make_type_name_node(type.name),
          selections: selections,
        )
      end
    end

    # Make a field AST.
    #
    # field     - The GraphQL::Field instance to make the fragment for.
    # arguments - A Hash of arguments to include in the field.
    # &blk      - A block to call with the AST and field type before returning
    #             the AST.
    #
    # Returns a GraphQL::Language::Nodes::Field instance or nil if the created
    # AST was invalid for having no selections or missing required arguments.
    def field_ast(field, arguments = {}, &blk)
      type = field.type.unwrap

      # Bail unless we have the required arguments.
      required_args_are_present = field.arguments.all? do |arg_name, arg|
        arguments.key?(arg_name) || valid_input?(arg.type, nil)
      end

      if !required_args_are_present
        nil
      else
        f_alias = field.name == 'id' ? nil : random_alias
        f_args = arguments.map do |name, value|
          GraphQL::Language::Nodes::Argument.new(name: name, value: value)
        end

        GraphQL::Language::Nodes::Field.new(name: field.name, alias: f_alias, arguments: f_args)
      end
    end

    # Make a field AST for a node field.
    #
    # field - The GraphQL::Field instance to make the fragment for.
    #
    # Returns a GraphQL::Language::Nodes::Field instance.
    def node_field_ast(field)
      f_ast = field_ast(field)
      return nil if f_ast.nil?
      type = field.type.unwrap
      selections = f_ast.selections.dup

      if type.kind.object?
        selections << field_ast(type.get_field('id'))
      else
        possible_node_types(type).each do |if_type|
          selections << inline_fragment_ast(if_type, with_children: false)
        end
      end

      selections.compact!

      if f_ast.respond_to?(:merge) # GraphQL-Ruby 1.9+
        f_ast = f_ast.merge(selections: selections)
      else
        f_ast.selections = selections
      end
      f_ast
    end

    # Make a field AST for an edges field.
    #
    # field - The GraphQL::Field instance to make the fragment for.
    #
    # Returns a GraphQL::Language::Nodes::Field instance.
    def edges_field_ast(field)
      f_ast = field_ast(field)
      return nil if f_ast.nil?
      node_fields = [node_field_ast(field.type.unwrap.get_field('node'))]
      if f_ast.respond_to?(:merge) # GraphQL-Ruby 1.9+
        f_ast.merge(selections: f_ast.selections + node_fields)
      else
        f_ast.selections.concat(node_fields)
        f_ast
      end
    end

    # Make a field AST for a connection field.
    #
    # field - The GraphQL::Field instance to make the fragment for.
    #
    # Returns a GraphQL::Language::Nodes::Field instance or nil if the created
    # AST was invalid for missing required arguments.
    def connection_field_ast(field)
      f_ast = field_ast(field, connection_arguments)
      return nil if f_ast.nil?
      edges_fields = [edges_field_ast(field.type.unwrap.get_field('edges'))]
      if f_ast.respond_to?(:merge) # GraphQL-Ruby 1.9+
        f_ast.merge(selections: f_ast.selections + edges_fields)
      else
        f_ast.selections.concat(edges_fields)
        f_ast
      end
    end

    # Is this field for a relay node?
    #
    # field - A GraphQL::Field instance.
    #
    # Returns true if the field's type includes the `Node` interface or is a
    # union or interface with a possible type that includes the `Node` interface
    # Returns false otherwise.
    def node_field?(field)
      type = field.type.unwrap
      kind = type.kind

      if kind.object?
        node_types.include?(type)
      elsif kind.interface? || kind.union?
        possible_node_types(type).any?
      end
    end

    # Is this field for a relay connection?
    #
    # field - A GraphQL::Field instance.
    #
    # Returns true if this field's type has a `edges` field whose type has a
    # `node` field that is a relay node. Returns false otherwise.
    def connection_field?(field)
      type = field.type.unwrap

      if edges_field = type.get_field('edges')
        edges = edges_field.type.unwrap
        if node_field = edges.get_field('node')
          return node_field?(node_field)
        end
      end

      false
    end

    # Get the possible types of a union or interface.
    #
    # type - A GraphQL::UnionType or GraphQL::InterfaceType instance.
    #
    # Returns an Array of GraphQL::ObjectType instances.
    def possible_types(type)
      if type.kind.interface?
        schema.possible_types(type)
      elsif type.kind.union?
        type.possible_types
      end
    end

    # Get the possible types of a union or interface that are relay nodes.
    #
    # type - A GraphQL::UnionType or GraphQL::InterfaceType instance.
    #
    # Returns an Array of GraphQL::ObjectType instances.
    def possible_node_types(type)
      possible_types(type) & node_types
    end

    # Get the types that implement the `Node` interface.
    #
    # Returns an Array of GraphQL::ObjectType instances.
    def node_types
      schema.possible_types(node_interface)
    end

    # Get the `Node` interface.
    #
    # Returns a GraphQL::InterfaceType instance.
    def node_interface
      schema.types['Node']
    end

    # Make a random alias for a field.
    #
    # Returns a twelve character random String.
    def random_alias
      12.times.map { (SecureRandom.random_number(26) + 97).chr }.join
    end

    def valid_input?(type, input)
      type.valid_isolated_input?(input)
    end

    def make_type_name_node(type_name)
      GraphQL::Language::Nodes::TypeName.new(name: type_name)
    end
  end
end
