require 'graphql/relay/walker'
require 'graphql/client'

describe GraphQL::Relay::Walker::QueryBuilder do
  [
    GraphQL::Client.load_schema('spec/fixtures/swapi_schema.json'),
    GraphQL::Schema.from_definition("spec/fixtures/swapi_schema.graphql")
  ].each do |schema|
    describe "With #{schema.class} schema" do
      let(:query_path)     { 'spec/fixtures/swapi_query.graphql' }
      let(:client)         { GraphQL::Client.new(schema: schema) }
      let(:query_builder)  { described_class.new(schema) }
      let(:ast)            { query_builder.ast }
      let(:query_string)   { query_builder.query_string }
      describe 'ast' do
        subject { ast }

        it 'adds an alias to all fields except id and node' do
          fields(ast).reject do |node|
            %w[node id].include?(node.name)
          end.each do |field|
            expect(field.alias).not_to be_nil
          end
        end
      end

      describe 'query_string' do
        subject { query_string }

        it 'generates a valid query for the schema' do
          expect { client.parse(query_string) }.not_to raise_error
        end

        describe 'with aliases removed' do
          it 'matches the expected query string' do
            # Replace the aliases, leaving the leading whitespace in place
            string_without_aliases = subject.gsub(/  [a-z]{12}: /, "  ")
            expect(string_without_aliases).to eq(File.read(query_path).strip)
          end
        end
      end

      def fields(ast)
        nodes(ast).select { |node| node.is_a?(GraphQL::Language::Nodes::Field) }
      end

      def nodes(ast)
        children = if ast.respond_to?(:selections)
                     ast.selections
                   elsif ast.respond_to?(:definitions)
                     ast.definitions
                   else
                     []
        end

        children + children.map { |child| nodes(child) }.flatten
      end
    end
  end
end
