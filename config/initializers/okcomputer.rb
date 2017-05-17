require 'breaker/rails_cache/repo'
Breaker.repo = Breaker::RailsCache::Repo.new

Breaker.callback(:after_open) do |circuit|
  alert_msg = "Circuit  #{circuit.name} Open"
    puts alert_msg
end

Breaker.callback(:after_close) do |circuit|
  alert_msg = "Circuit #{circuit.name} Closed"
    puts alert_msg
end

class CircuitHttpCheck < OkComputer::HttpCheck
  attr_accessor :proxy, :host

  def initialize(proxy, host)
    self.proxy = proxy
    self.host = host
  end

  def perform_request
    Breaker.circuit(host,  timeout: 3, failure_threshold: 3, failure_count_ttl: 60, retry_timeout: 10, half_open_timeout: 0.1 ) do
      open(proxy, "HOST" => host)
    end
  end
end

OkComputer::Registry.register "cicuit-test", CircuitHttpCheck.new("http://localhost:26808", "www.google.com")
