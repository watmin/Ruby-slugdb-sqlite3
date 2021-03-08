# SlugDB::SQLite3

A lightweight, NoSQL, file based database backed by SQLite3.

I wanted a tiny database for an embedded project that could follow the advanced data modelling techniques for NoSQL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'slugdb-sqlite3'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install slugdb-sqlite3

## Usage

Checkout the regular SlugDB then come back here. This is the same interface using SQLite3 instead of PStore with the caveat that index names must be strings, cannot be symbols.

Basic usage

```ruby
require 'slugdb/sqlite3'
# => true

# Create a database

sdb = SlugDB::SQLite3.new('./data.slug')
# => #<SlugDB::SQLite3:0x000055dbc5eb72a0
#  @sdb=
#   #<SQLite3::Database:0x000055dbc5eb7138
#    @authorizer=nil,
#    @busy_handler=nil,
#    @collations={},
#    @encoding=#<Encoding:UTF-8>,
#    @functions={},
#    @readonly=false,
#    @results_as_hash=nil,
#    @tracefunc=nil,
#    @type_translation=nil,
#    @type_translator=#<Proc:0x000055dbc5ca5188 /home/john/.rbenv/versions/3.0.0/lib/ruby/gems/3.0.0/gems/sqlite3-1.4.2/lib/sqlite3/database.rb:722 (lambda)>>>

# Put some data in it

sdb.put_item(pk: 'awesome#partition#1#', sk: 'metadata#')
# => {:pk=>"awesome#partition#1#", :sk=>"metadata#"}

# Read it back

sdb.get_item(pk: 'awesome#partition#1#', sk: 'metadata#')
# => {:pk=>"awesome#partition#1#", :sk=>"metadata#"}

# Put in some more data

sdb.put_item(pk: 'awesome#partition#1#', sk: 'something#useful#')
# => {:pk=>"awesome#partition#1#", :sk=>"something#useful#"}

# Query our records

sdb.query(pk: 'awesome#partition#1#')
# => [{:pk=>"awesome#partition#1#", :sk=>"metadata#"},
#  {:pk=>"awesome#partition#1#", :sk=>"something#useful#"}]
```

## Performance

Using Ubuntu 20.04 on an i7-10710U with Ruby `3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-linux]` I got the following:

```
john@devbox:~/work/ruby-slugdb-sqlite3$ bundle exec bin/benchmark
Rehearsal -------------------------------------------------------------------------------
put_item 5 partitions, 1000 items             3.257310   2.628153   5.885463 ( 17.955709)
put_item 50 partitions, 100 items             2.448559   2.243897   4.692456 ( 16.230796)
put_item 500 partitions, 10 items             2.918192   2.362401   5.280593 ( 16.944482)
put_item 5000 partitions, 1 items             2.493245   2.292205   4.785450 ( 16.391882)
2 indexes put_item 5 partitions, 1000 items   3.839494   3.019077   6.858571 ( 19.569620)
2 indexes put_item 50 partitions, 100 items   4.034768   3.155123   7.189891 ( 19.707652)
2 indexes put_item 500 partitions, 10 items   4.653889   3.610218   8.264107 ( 22.149808)
2 indexes put_item 5000 partitions, 1 items   4.130269   3.220645   7.350914 ( 20.107618)
put_item, get_item 5 partitions, 1000 items   2.060286   1.840930   3.901216 ( 14.719933)
put_item, get_item 50 partitions, 100 items   2.461780   2.057571   4.519351 ( 15.747244)
put_item, get_item 500 partitions, 10 items   3.235899   2.735682   5.971581 ( 17.945475)
put_item, get_item 5000 partitions, 1 items   2.970254   2.439286   5.409540 ( 17.297003)
--------------------------------------------------------------------- total: 70.109133sec

                                                  user     system      total        real
put_item 5 partitions, 1000 items             2.547680   2.312878   4.860558 ( 16.370065)
put_item 50 partitions, 100 items             3.387639   3.059782   6.447421 ( 18.399558)
put_item 500 partitions, 10 items             3.105934   2.880162   5.986096 ( 18.292644)
put_item 5000 partitions, 1 items             2.998857   2.688083   5.686940 ( 17.614748)
2 indexes put_item 5 partitions, 1000 items   3.712199   2.853161   6.565360 ( 19.003753)
2 indexes put_item 50 partitions, 100 items   4.180586   3.321287   7.501873 ( 20.203936)
2 indexes put_item 500 partitions, 10 items   4.342980   3.487185   7.830165 ( 20.940714)
2 indexes put_item 5000 partitions, 1 items   4.306121   3.332199   7.638320 ( 20.226231)
put_item, get_item 5 partitions, 1000 items   2.431277   2.235503   4.666780 ( 16.193609)
put_item, get_item 50 partitions, 100 items   2.636079   2.477241   5.113320 ( 16.677008)
put_item, get_item 500 partitions, 10 items   2.267650   1.782565   4.050215 ( 15.191621)
put_item, get_item 5000 partitions, 1 items   2.691626   2.369711   5.061337 ( 16.854689)
```

This is staggeringly better than SlugDB's PStore implementation. If you want performance and a small extra dep of SQLite3, then use this.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/watmin/Ruby-slugdb-sqlite3. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/watmin/Ruby-slugdb-sqlite3/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SlugDB project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/watmin/Ruby-slugdb-sqlite3/blob/master/CODE_OF_CONDUCT.md).
