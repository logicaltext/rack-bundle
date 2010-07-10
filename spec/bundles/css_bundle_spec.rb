require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Rack::Bundle::CSSBundle do
  before do
    reset_file  = File.join(FIXTURES_PATH, 'reset.css')
    screen_file = File.join(FIXTURES_PATH, 'screen.css')
    @files      = [reset_file, screen_file]
    @bundle      = Rack::Bundle::CSSBundle.new *@files
  end
  
  it 'makes the contents of one or more stylesheets accessible via #contents' do
    @bundle.contents.should == [$reset, $screen].join("\n")
  end
  
  it 'creates an MD5 hash out of the bundle file names and modified times' do
    data = @files.inject([]) { |acc, file| acc << file << ::File.mtime(file) }
    expected = MD5.new(data.join(' ')).to_s
    @bundle.hash.should == expected
  end
end