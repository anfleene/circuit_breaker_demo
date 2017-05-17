# Demo of how to use a Circuit Breaker in Ruby

This demo is designed to use [Toxiproxy](https://github.com/Shopify/toxiproxy) proxying google.com to show how a Circuit Works


## Installing/Running Toxiproxy

Install instructions can be found in [Toxiproxy's README](https://github.com/Shopify/toxiproxy#1-installing-toxiproxy)

To install on osx:

```bash
brew tap shopify/shopify
brew install toxiproxy
```

```bash
# to start the toxiproxy-server run
toxiproxy-server
```

Once the server is running you can create a proxy to allow traffic to
google.com

```bash
toxiproxy-cli create breaker-test --listen localhost:26808 --upstream www.google.com:80
```

To inspect the proxy run:

```bash
toxiproxy-cli inspect breaker-test
```

## Running the rails app

```bash
# ensure you have working version of ruby 2
ruby --version
# install bundler
gem install bundler
# install dependencies
bundle install
# Launch a rails server with multiple threads
bundle exec puma -t 10:100 -p 3000 -e production
```

## Testing the proxy

Visiting [http://localhost:3000/okcomputer/cicuit-test.txt](http://localhost:3000/okcomputer/cicuit-test.txt) should return:

> cicuit-test: PASSED HTTP check successful (0s)

## Tiggering the circuit

To trigger the circuit enable a toxic with latency longer than the circuit timeout(3 seconds)

```bash
# add 10 seconds of latency
toxiproxy-cli toxic a breaker-test -t latency -a latency=10000
```

Make a few requests they should start to show:
> cicuit-test: FAILED Error: 'execution expired' (3s)

Once you've made enough failures you will see:
> cicuit-test: FAILED Error: 'Refusing to run code while circuit www.google.com is open' (0s) 

You will also see `Circuit  www.google.com Open` in the rails log output

## Closing the circuit

To close the circuit you must remove the toxic from the proxy

```bash
toxiproxy-cli toxic r breaker-test -n latency_downstream
```

Once the retry timeout has expired(10 seconds) the circuit will
attempt to make requests again and now that the toxic is removed the
request should succeed and and the rails log should show

> Circuit www.google.com Closed

## The Code

The important bits of code for this are in the [Gemfile](http://github.com/anfleene/circuit_breaker_demo/blob/master/Gemfile) and the [okcomputer.rb rails initializer](http://github.com/anfleene/circuit_breaker_demo/blob/master/config/initializers/okcomputer.rb)
Where I define the [OkComputer](https://github.com/sportngin/okcomputer)
health check that wraps an http check in a circuit breaker.


