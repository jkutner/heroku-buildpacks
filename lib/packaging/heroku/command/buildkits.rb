# TODO: plural or singular?
require "heroku/command"
require "tmpdir"
require "rest_client"

# manage your build kit
#
class Heroku::Command::Buildkits < Heroku::Command::Base

  # buildkits:list
  #
  # list the buildpacks in your kit
  #
  def list
    styled_header "Buildpacks in #{auth.user}'s kit"
    packs = json_decode(server["/buildkit"].get)
    styled_array packs.map{|b| "#{b['org']}/#{b['name']}" }
  end
  alias_method :index, :list

  # buildkits:setup
  #
  # set up the BUILDPACK_URL for an app
  #
  def setup
    action "Modifying BUILDPACK_URL for #{app}" do
      buildpack_url = buildkit_host + "/buildkit/#{auth.user}.tgz"
      api.put_config_vars app, "BUILDPACK_URL" => buildpack_url
    end
  end

  # buildkits:url
  #
  # show BUILDPACK_URL for your kit
  #
  def url
    action "Modifying BUILDPACK_URL for #{app}" do
      buildpack_url = buildkit_host + "/buildkit/#{auth.user}.tgz"
      api.put_config_vars app, "BUILDPACK_URL" => buildpack_url
    end
  end

  # buildkits:add ORG/NAME
  #
  # add a buildpack to your kit
  #
  def add
    error("Must specify a buildpack name") if invalid_arguments.empty?
    while name = shift_argument
      action("Adding #{name} to your kit") do
        begin
          server["/buildkit/#{name}"].put({})
        rescue RestClient::ResourceNotFound
          error "No such buildpack: #{name}"
        rescue RestClient::Forbidden
          error "The #{name} buildpack is already in your kit"
        end
      end
    end
  end

  # buildkits:remove ORG/NAME
  #
  # remove a buildpack from your kit
  #
  def remove
    error("Must specify a buildpack name") if invalid_arguments.empty?
    while name = shift_argument
      action("Removing #{name} from your kit") do
        begin
          server["/buildkit/#{name}"].delete({})
        rescue RestClient::ResourceNotFound
          error "The #{name} buildpack is not in your kit"
        end
      end
    end
  end

  # TODO: remove duplication between buildpacks command?
  private

  def auth
    Heroku::Auth
  end

  def buildkit_host
    ENV["BUILDPACK_SERVER_URL"] || "https://buildkits.herokuapp.com"
  end

  def server
    RestClient::Resource.new(buildkit_host, :user => auth.user,
                             :password => auth.password)
  end
end
