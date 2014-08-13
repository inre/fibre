# Fibre

Fibre - fiber pool with events

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fibre'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fibre

Initialize pool:

    Fibre.pool_size = 10

## Usage

```ruby
Fibre.pool_size = 10
Fibre.pool.checkout do
  puts "runned in fiber"
end
# some fiber raised exception
using EventObject
Fibre.pool.on :error do |e|
  puts e.to_s
  exit
end
```

## Contributing

1. Fork it ( https://github.com/chelovekov/fibre/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
