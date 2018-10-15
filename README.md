# Slimpay

[![Gem Version](https://badge.fury.io/rb/slimpay-client.svg)](http://badge.fury.io/rb/slimpay-client)

This library provides convenient access to the Slimpay API from applications written in the Ruby language.

## Installation

SlimpayClient is distributed as a gem, which is how it should be used in your app.

Include the gem in your Gemfile:

    gem 'slimpay-client', '~> 1.0'

## Usage

### Configuration

If you use Rails place this code in `config/initializers/slimpay.rb`:

```ruby
Slimpay.configure do |s|
	s.client_id = ENV["SLIMPAY_CLIENT_ID"]
	s.client_secret = ENV["SLIMPAY_CLIENT_SECRET"]
	s.creditor_reference = ENV["SLIMPAY_CREDITOR_REFERENCE"]
	s.sandbox = !Rails.env.production?
	s.logger = Rails.logger
end
 ```

`creditor_reference` is not used inside the library, it's just a convenient way to store this variable and reuse it after in your code with `Slimpay.creditor_reference`.

The methods are dynamically created, the first call to `Slimpay.base` will call Slimpay API and generate a methods for each endpoints.

### Example

```ruby
recurrent_direct_debit = Slimpay.base.search_recurrent_direct_debits(reference: "QWERTY1234", activated: true).recurrentDirectDebits[0]
recurrent_direct_debit = Slimpay.base.get_recurrent_direct_debits(id: recurrent_direct_debit.data['id'])
recurrent_direct_debit.cancel_recurrent_debit
```

## Author

- [Jonathan VUKOVICH TRIBOUHARET](https://github.com/jonathantribouharet) ([@johnvuko](https://twitter.com/johnvuko))

## License

This gem is released under the MIT license. See the LICENSE file for more info.
