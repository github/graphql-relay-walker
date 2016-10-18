# GitHub Walker

GraphQL Relay Walker example: *walk GitHub's GraphQL API*

## Usage

You can use this code as a library:

```ruby
require "github_walker"

# Walk the graph, printing each object we come across.
GitHubWalker.walk do |frame|
  msg = "Found object `#{frame.gid}`"
  msg += " via object `#{frame.parent.gid}`" += if frame.parent
  puts message
end
```

or you can run the provided script:

```bash
# install dependencies
bundle install

# Walk the graph.
script/walk
```

either way, you need to have a GitHub API token in your environment:

```bash
export GITHUB_ACCESS_TOKEN=<my access token>
```

You can make one of these tokens [here](https://github.com/settings/tokens). Your token will need these scopes:

- `read:gpg_key`
- `read:org`
- `read:public_key`
- `read:repo_hook`
- `repo`
- `user`
