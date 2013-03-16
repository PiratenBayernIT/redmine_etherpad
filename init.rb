#
# vendor/plugins/redmine_etherpad/init.rb
#

require 'redmine'
require 'uri'

Redmine::Plugin.register :redmine_etherpad do
  name 'Redmine Etherpad plugin'
  author 'Charlie DeTar'
  description 'Embed etherpad-lite pads in redmine wikis.'
  version '0.0.1'
  url 'https://github.com/yourcelf/redmine_etherpad'
  author_url 'https://github.com/PiratenBayernIT'

  Redmine::WikiFormatting::Macros.register do
    desc "Embed etherpad"
    macro :etherpad do |obj, args|
      conf = Redmine::Configuration['etherpad']
      unless conf and conf['host'] 
        raise "Please define etherpad parameters in configuration.yml."
      end

      # Defaults from configuration.
      controls = {
        'showControls' => conf.fetch('showControls', true),
        'showChat' => conf.fetch('showChat', true),
        'showLineNumbers' => conf.fetch('showLineNumbers', false),
        'useMonospaceFont' => conf.fetch('useMonospaceFont', false),
        'noColors' => conf.fetch('noColors', false),
        'width' => conf.fetch('width', '640px'),
        'height' => conf.fetch('height', '480px'),
        'fullScreen' => conf.fetch('fullScreen', true),
        'team' => conf.fetch("team", nil),
        'host' => conf.fetch("host"),
        'scheme' => conf.fetch("scheme", "https")
      }
        
      # Override default control settings with given arguments.
      padname, *params = args
      for param in params
        key, val = param.strip().split("=")
        unless controls.has_key?(key)
          raise "#{key} not a recognized parameter."
        else
          controls[key] = val
        end
      end

      # Set current user name.
      if User.current
        controls['userName'] = User.current.name
      elsif conf.fetch('loginRequired', true)
        return "TODO: embed read-only."
      end

      # Extract settings which are not settings for Etherpad.
      width = controls.delete('width')
      height = controls.delete('height')
      team = controls.delete('team')
      host = controls.delete('host')
      scheme = controls.delete('scheme')

      def hash_to_querystring(hash)
        hash.keys.inject('') do |query_string, key|
          query_string << '&' unless key == hash.keys.first
          query_string << "#{URI.encode(key.to_s)}=#{URI.encode(hash[key].to_s)}"
        end
      end
      
      # Hack for piratenpad.de. When referencing existings pads, everything is ok.
      # But when creating new pads, an Etherpad is created instead of an Etherpad Lite.
      # To fix this, append "/p/" when no team is given
      # Teampads still use Etherpad, so nothing has to be added in this case.
      if host == "piratenpad.de" and not team
        host = "piratenpad.de/p"
      end

      padsrc = team ? "#{scheme}://#{team}.#{host}/" : "#{scheme}://#{host}/"
      return CGI::unescapeHTML("<iframe src='#{padsrc}#{URI.encode(padname)}?#{hash_to_querystring(controls)}' width='#{width}' height='#{height}'></iframe>").html_safe
    end
  end
end

# vim: set sw=2 ts=2 sts=2 expandtab: #
