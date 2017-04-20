# GraphQL Relay Walker [![Build Status](https://travis-ci.org/github/graphql-relay-walker.svg?branch=master&a=b)](https://travis-ci.org/github/graphql-relay-walker)  [![Gem Version](https://badge.fury.io/rb/graphql-relay-walker.svg)](http://badge.fury.io/rb/graphql-relay-walker)

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

## Compatibility & Versioning

This project is designed to work with MRI Ruby 2.2.2 or greater. It may work on other versions of Ruby.

All releases adhere to strict [semantic versioning](http://semver.org). For Example, major.minor.patch-pre (aka. stick.carrot.oops-peek).

## Contributions & Feedback

We love community contributions! If you're planning to send us a pull request, please make sure read our [Contributing Guidelines](https://github.com/github/graphql-relay-walker/blob/master/CONTRIBUTING.md) first.

Found a bug or have a question? Open up [an issue](https://github.com/github/graphql-relay-walker/issues/new).

## License

The MIT License (MIT)

Copyright (C) 2016 GitHub, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
