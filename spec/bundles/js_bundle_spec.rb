require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Rack::Bundle::JSBundle do
  before do
    jquery_file  = File.join(FIXTURES_PATH, 'jquery-1.4.1.min.js')
    mylib_file   = File.join(FIXTURES_PATH, 'mylib.js')
    @files       = [jquery_file, mylib_file]
    @bundle      = Rack::Bundle::JSBundle.new *@files
  end
  
  it 'makes the contents of one or more Javascript file(s) accessible via #contents' do
    @bundle.contents.should == [$jquery, $mylib].join(';')
  end
  
  it 'creates an MD5 hash out of the bundle file names modified times' do
    data = @files.inject([]) { |acc, file| acc << file << ::File.mtime(file) }
    expected = MD5.new(data.join(' ')).to_s
    @bundle.hash.should == expected
  end
end