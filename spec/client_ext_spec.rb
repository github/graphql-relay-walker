require 'graphql/client'
require 'graphql/relay/walker'
require 'graphql/relay/walker/client_ext'

describe GraphQL::Relay::Walker::ClientExt do
  let(:schema_path)    { 'spec/fixtures/swapi_schema.json' }
  let(:query_path)     { 'spec/fixtures/swapi_query.graphql' }
  let(:schema)         { GraphQL::Client.load_schema(schema_path) }
  let(:client)         { GraphQL::Client.new(schema: schema) }

  describe '#walk' do
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
