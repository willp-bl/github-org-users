#!/usr/bin/env ruby
require 'octokit'
require 'json'

github_token_env_var = "GITHUB_TOKEN".freeze
github_org_env_var = "GITHUB_ORG".freeze

if !ENV.has_key? github_token_env_var
    puts "You need to set #{github_token_env_var}"
    exit 1
end

if !ENV.has_key? github_org_env_var
    puts "You need to set #{github_org_env_var}"
    exit 1
end

github_org = ENV[github_org_env_var]

client = Octokit::Client.new(:access_token => "#{ENV[github_token_env_var]}")
# so we don't have to manually handle pagination in the responses from the api
client.auto_paginate = true

def print_user(login, name, email, role, membership)
    info = { username: login,
                  name: name,
                  email: email,
                  role: role,
                  membership: membership }
    puts "#{login}, #{name}, #{role}, #{membership}, "
    info
end

puts "login, name, role, membership, "

members = client.organization_members(github_org).map { |member|
    membership = client.organization_membership(github_org, { user: member.login })
    user_info = client.user member.login
    print_user(member.login, user_info.name, user_info.email, membership.role, 'member')
}

invitations = client.organization_invitations(github_org).map { |member|
    membership = client.organization_membership(github_org, { user: member.login })
    user_info = client.user member.login
    print_user(member.login, user_info.name, user_info.email, membership.role, 'invitation_pending')
}

collaborators = client.outside_collaborators(github_org).map { |member|
    user_info = client.user member.login
    os_message = 'outside_collaborator'
    print_user(member.login, user_info.name, user_info.email, os_message, os_message)
}

all_users = members + invitations + collaborators

puts "WARNING: merged hash has missed some users" unless members.length+invitations.length+collaborators.length == all_users.length

# puts "#{all_users.to_json}"
