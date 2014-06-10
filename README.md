# Paxum gem

[![Code Climate](https://codeclimate.com/github/Mehonoshin/paxum.png)](https://codeclimate.com/github/Mehonoshin/paxum)

Ruby wrapper for Paxum API

A list of availible api methods: https://www.paxum.com/payment_docs/page.php?name=apiIntroduction

## Installation

Add to Gemfile:

```ruby
gem 'paxum'
```
## Usage

Anywhere in your application use gem in following way:

```ruby
  options = {
    ...
  }

  Paxum.method_name("sender@example.com", "api_secret_token_from_your_paxum_profile_page", options)

```

## Implemented API methods

### Transfer Funds
```ruby
  options = {
    currency: "usd",
    to: "recipient@example.com",
    from: "sender@example.com",
    amount: 100,
    note: "1 example.com" // allowes to insert additional text at paxum transaction description field
  }

  Paxum.transfer_funds("sender@example.com", "api_secret_token_from_your_paxum_profile_page", options)
```

### Balance Inquiry
```ruby
  paxum_api = Paxum.new("user@example.com", "secret_token")
  paxum_api.balance(1111) # balance for account ID 1111
```


## Contributing

Feel free to make PRs.

## License

Released by independent developer, under the MIT License.
