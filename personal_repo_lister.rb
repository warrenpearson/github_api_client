#!/usr/bin/env ruby

require 'json'
require 'nitlink'
require 'typhoeus'

# Retrieve repo list for provided user
# and personal access token
class PersonalRepoLister
  def initialize(user, token)
    @user  = user
    @token = token
    @base_url = 'https://api.github.com/user/repos?page='
  end

  def run
    page = 1
    keep_on = true

    while keep_on
      keep_on = show_results_for(page)
      page += 1
    end
  end

  def show_results_for(page)
    keep_on = true

    url = @base_url + page.to_s
    response = Typhoeus.get(url, userpwd: "#{@user}:#{@token}")
    if response.success?
      json = JSON.parse(response.body)
      show(json)
      last_url = check_link_header(response)
      keep_on = false if last_url == url || last_url.nil?
    end
    keep_on
  end

  def show(json)
    json.each do |repo|
      print "#{repo['full_name']} ("
      if repo['private']
        print 'private)'
      else
        print 'public)'
      end
      puts
    end
  end

  def check_link_header(response)
    link_parser = Nitlink::Parser.new
    links = link_parser.parse(response)
    return links.by_rel('last').target.to_s if links.by_rel('last')
    nil
  end
end

PersonalRepoLister.new(ARGV[0], ARGV[1]).run
