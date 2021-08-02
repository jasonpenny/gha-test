#!/usr/bin/env ruby

# frozen_string_literal: true

# Outputs a pullRequestId for use in GitHub graphql API mutations
# requires $GITHUB_TOKEN env var and a single argument of the PR number.

require 'net/http'
require 'uri'
require 'json'

def request(query)
  github_uri = URI('https://api.github.com/graphql')

  req = Net::HTTP::Post.new(
    github_uri,
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}"
  )
  req.body = { query: query }.to_json

  res = Net::HTTP.start(github_uri.hostname, github_uri.port, use_ssl: true) { |http| http.request(req) }

  JSON.parse(res.body)
end

if ENV['GITHUB_TOKEN'].nil?
  puts '$GITHUB_TOKEN env var must be set'
  exit(1)
end

if ARGV.length != 1
  puts "Usage: #{__FILE__} <PR number>"
  exit(1)
end

query = <<-GRAPHQL
  {
    repository(owner:"jasonpenny", name:"gha-test") {
      pullRequest(number: #{ARGV[0]}) {
        id
      }
    }
  }
GRAPHQL
body = request(query)
puts body['data']['repository']['pullRequest']['id']
