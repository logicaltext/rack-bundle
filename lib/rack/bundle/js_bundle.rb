require 'md5'

class Rack::Bundle::JSBundle
  attr_accessor :contents, :hash
  def initialize *files
    @files = files
  end
  
  def extension
    'js'
  end
  
  def contents
    return @contents if @contents
    stream = @files.inject([]) { |acc, file| acc << ::File.read(file) }
    @contents = stream.join ';'
  end

  def hash
    return @hash if @hash
    data = @files.inject([]) { |acc, file| acc << file << ::File.mtime(file) }
    @hash = MD5.new(data.join(' ')).to_s
  end

  def == bundle
    self.class == bundle.class && hash == bundle.hash
  end  
end