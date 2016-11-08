module GraphQL::Relay::Walker
  class QueryBuilder
    DEFAULT_ARGUMENTS = {"first" => 5}
    BASE_QUERY = "query($id: ID!) { node(id: $id) {} }"

    attr_reader :schema, :connection_arguments, :ast

    # Initialize a new QueryBuilder.
    #
    # schema                - The GraphQL::Schema to build a query for.
    # connection_arguments: - A Hash or arguments to use for connection fields
    #                         (optional).
    #
    # Returns nothing.
    def initialize(schema, connection_arguments: DEFAULT_ARGUMENTS)
      @schema = schema
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
          selections << inline_fragment_ast(type)
        end

        selections.compact!
      end
    end

    # Private: Make a AST of the given type.
    #
    # klass             - The GraphQL::Language::Nodes::AbstractNode subclass
    #                     to create.
    # needs_selections: - Boolean. Will this AST be invalid if it doesn't have
    #                     any selections?
    #
    # Returns a GraphQL::Language::Nodes::AbstractNode subclass instance or nil
    # if the created AST was invalid for having no selections.
    def make(klass, needs_selections: true)
      k_ast = klass.new
      yield(k_ast) if block_given?
      k_ast.selections.compact!

      if k_ast.selections.empty? && needs_selections
        nil
      else
        k_ast
      end
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
      make(GraphQL::Language::Nodes::InlineFragment) do |if_ast|
        if_ast.type = make_type_name_node(type.name)

        if with_children
          type.all_fields.each do |field|
            if node_field?(field)
              if_ast.selections << node_field_ast(field)
            elsif connection_field?(field)
              if_ast.selections << connection_field_ast(field)
            end
          end
        elsif id = type.get_field("id")
          if_ast.selections << field_ast(id)
        end
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
    def field_ast(field, arguments={}, &blk)
      type = field.type.unwrap

      # Bail unless we have the required arguments.
      return unless field.arguments.reject do |_, arg|
        valid_input?(arg.type, nil)
      end.all? do |name, _|
        arguments.key?(name)
      end

      make(GraphQL::Language::Nodes::Field, needs_selections: !type.kind.scalar?) do |f_ast|
        f_ast.name = field.name
        f_ast.alias = random_alias unless field.name == "id"
        f_ast.arguments = arguments.map do |name, value|
          GraphQL::Language::Nodes::Argument.new(name: name, value: value)
        end

        blk.call(f_ast, type) if blk
      end
    end

    # Make a field AST for a node field.
    #
    # field - The GraphQL::Field instance to make the fragment for.
    #
    # Returns a GraphQL::Language::Nodes::Field instance.
    def node_field_ast(field)
      field_ast(field) do |f_ast, type|
        selections = f_ast.selections

        if type.kind.object?
           selections << field_ast(type.get_field("id"))
        else
          possible_node_types(type).each do |if_type|
             selections << inline_fragment_ast(if_type, with_children: false)
          end
        end
      end
    end

    # Make a field AST for an edges field.
    #
    # field - The GraphQL::Field instance to make the fragment for.
    #
    # Returns a GraphQL::Language::Nodes::Field instance.
    def edges_field_ast(field)
      field_ast(field) do |f_ast, type|
        f_ast.selections << node_field_ast(type.get_field("node"))
      end
    end

    # Make a field AST for a connection field.
    #
    # field - The GraphQL::Field instance to make the fragment for.
    #
    # Returns a GraphQL::Language::Nodes::Field instance or nil if the created
    # AST was invalid for missing required arguments.
    def connection_field_ast(field)
      field_ast(field, connection_arguments) do |f_ast, type|
        f_ast.selections << edges_field_ast(type.get_field("edges"))
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

      if edges_field = type.get_field("edges")
        edges = edges_field.type.unwrap
        if node_field = edges.get_field("node")
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
      schema.types["Node"]
    end

    # Make a random alias for a field.
    #
    # Returns a six character random String.
    def random_alias
      6.times.map { (SecureRandom.random_number(26) + 97).chr }.join
    end

    if GraphQL::VERSION >= "1.1.0"
      def valid_input?(type, input)
        allow_all = GraphQL::Schema::Warden.new(schema, ->(_) { false })
        type.valid_input?(input, allow_all)
      end
    else
      def valid_input?(type, input)
        type.valid_input?(input)
      end
    end

    if GraphQL::VERSION >= "1.0.0"
      def make_type_name_node(type_name)
        GraphQL::Language::Nodes::TypeName.new(name: type_name)
      end
    else
      def make_type_name_node(type_name)
        type_name
      end
    end
  end
end
