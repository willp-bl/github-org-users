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

def print_user(login, name, email, state, role, inviter, membership)
    info = { username: login,
                  name: name,
                  email: email,
                  state: state,
                  role: role,
                  inviter: inviter,
                  membership: membership }
    puts "#{login}, #{name}, #{email}, #{state}, #{role}, #{inviter}, #{membership}, "
    info
end

puts "login, name, email, state, role, inviter, membership, "

members = client.organization_members(github_org).map { |member|
    membership = client.organization_membership(github_org, { user: member.login })
    user_info = client.user member.login
    print_user(member.login, user_info.name, user_info.email, membership.state, membership.role, 'null', 'member')
}

invitations = client.organization_invitations(github_org).map { |member|
    membership = client.organization_membership(github_org, { user: member.login })
    user_info = client.user member.login
    pending_message = 'invitation_pending'
    print_user(member.login, user_info.name, user_info.email, pending_message, membership.role, membership.inviter.login, pending_message)
}

collaborators = client.outside_collaborators(github_org).map { |member|
    user_info = client.user member.login
    os_message = 'outside_collaborator'
    print_user(member.login, user_info.name, user_info.email, os_message, os_message, 'null', os_message)
}

all_users = members + invitations + collaborators

puts "WARNING: merged hash has missed some users" unless members.length+invitations.length+collaborators.length == all_users.length

# puts "#{all_users.to_json}"
