#!/usr/bin/env ruby

# frozen_string_literal: true

# Outputs a pullRequestId for use in GitHub graphql API mutations
# requires $GITHUB_TOKEN env var and a single argument of the PR number.

require 'net/http'
require 'uri'
require 'json'

def request(body_obj)
  github_uri = URI('https://api.github.com/graphql')

  req = Net::HTTP::Post.new(
    github_uri,
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}"
  )
  req.body = body_obj.to_json

  res = Net::HTTP.start(github_uri.hostname, github_uri.port, use_ssl: true) { |http| http.request(req) }

  return JSON.parse(res.body)
end

def query_request(query)
  return request({ query: query })
end

def mutation_request(query, variables)
  return request({ query: query, variables: variables })
end

def get_pr_id_for_number(pr_number)
  query = <<-GRAPHQL
    {
      repository(owner:"jasonpenny", name:"gha-test") {
        pullRequest(number: #{pr_number}) {
          id
        }
      }
    }
  GRAPHQL
  return query_request(query)['data']['repository']['pullRequest']['id']
end

def enable_pull_request_auto_merge(pr_id)
  mutation = <<-GRAPHQL
    mutation($input: EnablePullRequestAutoMergeInput!) {
      enablePullRequestAutoMerge(input: $input) {
        pullRequest {
          id
        }
      }
    }
  GRAPHQL
  return mutation_request(mutation, { input: { pullRequestId: pr_id } })
end

if ENV['GITHUB_TOKEN'].nil?
  puts '$GITHUB_TOKEN env var must be set'
  exit(1)
end

if ARGV.length != 1
  puts "Usage: #{__FILE__} <PR number>"
  exit(1)
end

pr_id = get_pr_id_for_number(ARGV[0])

result = enable_pull_request_auto_merge(pr_id)
if !result["errors"].nil?
  puts result
  exit(1)
end
