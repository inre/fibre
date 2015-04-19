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
```
