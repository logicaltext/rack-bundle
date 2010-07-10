require 'tmpdir'

class Rack::Bundle::FileSystemStore
  attr_accessor :dir, :bundles
  
  def initialize dir = Dir.tmpdir
    @dir = dir
  end
  
  def find_bundle_file_by_hash hash
    found = Dir["#{dir}/rack-bundle-#{hash}.*"]
    found.any? ? found.first : nil
  end
    
  def has_bundle? bundle
    File.exists? "#{dir}/rack-bundle-#{bundle.hash}.#{bundle.extension}"
  end
  
  def add bundle
    File.open("#{dir}/rack-bundle-#{bundle.hash}.#{bundle.extension}", 'w') do |file|
      file << bundle.contents
    end    
  end    
end