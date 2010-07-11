require 'rack'
require 'nokogiri'

module Rack
  class Bundle
    SELECTORS = Struct.new('Selector', :js, :css).new(
      'head script[src$=".js"]:not([src^="http"])',
      'head link[href$=".css"]:not([href^="http"])'
    )
    attr_accessor :storage, :document, :public_dir
    autoload :FileSystemStore,  'rack/bundle/file_system_store'
    autoload :DatabaseStore,    'rack/bundle/database_store'
    autoload :JSBundle,         'rack/bundle/js_bundle'
    autoload :CSSBundle,        'rack/bundle/css_bundle'

    def initialize app, options = {}
      @app, @public_dir = app, options[:public_dir]
      @storage = options[:storage] || FileSystemStore.new(@public_dir)
      yield self if block_given?      
      raise ArgumentError, ":public_dir needs to be a directory" unless ::File.directory?(@public_dir.to_s)
    end

    def call env
      @env = env
      if match = %r(^/rack-bundle-(\w+)).match(@env['PATH_INFO'])
        bundle = @storage.find_bundle_file_by_hash match[1]
        bundle ? respond_with(bundle) : not_found
      else
        status, headers, @response = @app.call(@env)
        return [status, headers, @response] unless headers['Content-Type'] =~ /html/
        parse!
        replace_javascripts!
        replace_stylesheets!

        body = @document.to_html

        if headers['Content-Length']
          headers['Content-Length'] = body.length.to_s
        end

        [status, headers, [body]]
      end
    end

    def parse!
      # http://github.com/logicaltext/rack-bundle/commit/8e7d0282b05b01a0cbfa59b519242046437605f6
      body = ""
      @response.each do |part| body << part end
      @document = Nokogiri::HTML(body)
    end

    def replace_javascripts!
      return unless @document.css(SELECTORS.js).count > 1
      bundle = JSBundle.new *scripts
      @storage.add bundle unless @storage.has_bundle? bundle
      bundle_node = @document.create_element 'script',
        :type     => 'text/javascript',
        :src      => bundle_path(bundle),
        :charset  => 'utf-8'
      @document.css(SELECTORS.js).first.before(bundle_node)
      @document.css(SELECTORS.js).slice(1..-1).remove
      @document
    end

    def replace_stylesheets!
      return unless local_css_nodes.count > 1
      styles = local_css_nodes.group_by { |node| node.attribute('media').value rescue nil }
      styles.each do |media, nodes|
        next unless nodes.count > 1
        stylesheets = stylesheet_paths_for nodes
        bundle = CSSBundle.new *stylesheets
        @storage.add bundle unless @storage.has_bundle? bundle
        node = @document.create_element 'link',
          :rel    => 'stylesheet',
          :type   => 'text/css',
          :href   => bundle_path(bundle),
          :media  => media
        nodes.first.before(node)
        nodes.map { |node| node.remove }
      end
      @document
    end

    private
    def local_javascript_nodes
      @document.css(SELECTORS.js)
    end

    def local_css_nodes
      @document.css(SELECTORS.css)
    end

    def scripts
      local_javascript_nodes.inject([]) do |paths, node|
        path = ::File.join(@public_dir, node.attribute('src').value)
        unless ::File.exists?(path)
          path = ::File.join(Dir.pwd, 'tmp', node.attribute('src').value)
        end
        next unless ::File.exists?(path)
        paths << path
      end
    end

    def stylesheet_paths_for nodes
      nodes.inject([]) do |paths, node|
        path = ::File.join(@public_dir, node.attribute('href').value)
        unless ::File.exists?(path)
          path = ::File.join(Dir.pwd, 'tmp', node.attribute('href').value)
        end
        next unless ::File.exists?(path)
        paths << path
      end
    end

    def bundle_path bundle
      "/rack-bundle-#{bundle.hash}.#{bundle.extension}"
    end

    def not_found
      [404, {'Content-Type' => 'text/plain'}, ['Not Found']]
    end

    def respond_with bundle
      opts = { :urls => '/' }
      if storage.is_a?(FileSystemStore)
        opts[:root] = storage.dir
      else
        opts[:root] = File.join(Dir.pwd, 'tmp')
      end

      Rack::Static.new(@app, opts).call(@env)
    end

  end
end
