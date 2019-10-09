require 'graphql/client'
require 'graphql/relay/walker'
require 'graphql/relay/walker/client_ext'

describe GraphQL::Relay::Walker::ClientExt do
  [
    GraphQL::Client.load_schema('spec/fixtures/swapi_schema.json'),
    GraphQL::Schema.from_definition("spec/fixtures/swapi_schema.graphql")
  ].each do |schema|
    describe "with #{schema.class} schema" do
      describe '#walk' do
        let(:client) { GraphQL::Client.new(schema: schema) }
        it 'allows passing additional variables through to GraphQLClient#query' do
          expected = { variables: { 'foo' => 'bar', 'id' => '12345' }, context: {} }
          expect(client).to receive(:query).with(anything, expected).and_return({})
          client.walk(from_id: '12345', variables: { 'foo' => 'bar' })
        end

        it 'allows passing additional context through to GraphQLClient#query' do
          viewer   = Object.new
          expected = { variables: { 'id' => '12345' }, context: { viewer: viewer } }
          expect(client).to receive(:query).with(anything, expected).and_return({})
          client.walk(from_id: '12345', context: { viewer: viewer })
        end
      end
    end
  end
end
