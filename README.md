# GraphQL Relay Walker

![](https://cloud.githubusercontent.com/assets/1144197/19287829/9ce479b8-8fc0-11e6-975c-8d686e3e0783.jpg)

`GraphQL::Relay::Walker` is a Ruby library that generates queries for walking a [Relay](https://facebook.github.io/relay/docs/graphql-relay-specification.html#content) [GraphQL](http://graphql.org/) schema. Given a `GraphQL::Schema`, you can walk from a given starting point, exercising any defined connections. This can be useful for various kinds of automated testing. Check out the [GitHub Walker](./examples/github_walker) example to see it in action.

## Setup

You can install this library as a Ruby Gem:

```
$ gem install graphql-relay-walker
```

## Usage

```ruby
require "graphql/relay/walker"

id = "<some starting node id>"
query = GraphQL::Relay::Walker.query_string(client.schema)


GraphQL::Relay::Walker.walk(from_id: id) do |frame|
  # The global relay id of the object we're looking at.
  frame.gid

  # The frame where we discovered this object's GID.
  frame.parent

  # Execute the query and store the result in the frame.
  # The implementation here is up to you, but you should set
  # `frame.result` to the Hash result of executing the query.
  frame.result = execute(query, variables: {"id" => frame.gid})

  # Parse the results, adding any newly discovered IDs to our queue.
  frame.enqueue_found_gids
end
```

## Usage with `GraphQL::Client`

Requiring `graphql/relay/walker/client_ext` will add a `GraphQL::Client#walk` method. This simplifies things by allowing the client to build and execute the query for you.

Here's how you would walk the [SWAPI GraphQL Wrapper](https://github.com/graphql/swapi-graphql), starting from Luke Skywalker, assuming a client configuration like [this](https://github.com/github/graphql-client/blob/2761908e735e6d34bf6056d26e97de54d384aa14/README.md#configuration).

```ruby
require "graphql/relay/walker/client_ext"

skywalker_gid = "cGVvcGxlOjE="

SWAPI::Client.walk(from_id: skywalker_gid) do |frame|
  # The global relay id of the object we're looking at.
  frame.gid

  # The frame where we discovered this object's GID.
  frame.parent

  # The result of executing the query for this frame's GID.
  frame.result
end
```

## Development

1. Clone repository and install dependencies

  ```
  $ git clone https://github.com/github/graphql-relay-walker
  $ cd graphql-relay-walker
  $ bundle install
  ```

2. Run tests

  ```
  $ bundle exec rake
  ```
