require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Rack::Bundle::FileSystemStore do  
  before do
    @jsbundle, @cssbundle = make_js_bundle, make_css_bundle
    @storage = Rack::Bundle::FileSystemStore.new FIXTURES_PATH
    @storage.add @jsbundle
    @storage.add @cssbundle    
  end
  
  it "stores bundles in a location specified on the argument when instancing" do
    Rack::Bundle::FileSystemStore.new(FIXTURES_PATH).dir.should == FIXTURES_PATH
  end
  
  it "defaults to the system's temporary dir" do
    subject.dir.should == Dir.tmpdir
  end
  
  it "finds a bundle file by its hash on #find_bundle_by_hash" do
    expected = File.join(@storage.dir, "rack-bundle-#{@jsbundle.hash}.js")
    @storage.find_bundle_file_by_hash(@jsbundle.hash).should == expected
  end
    
  context 'storing bundles in the file system' do
    it "checks if a bundle exists with #has_bundle?" do
      @storage.has_bundle?(@jsbundle).should be_true
    end

    it 'skips saving a bundle if one with a matching hash already exists' do
      File.should_not_receive(:open)
    end
    
    it 'stores Javascripts in a single Javascript file' do
      File.size(File.join(@storage.dir, "rack-bundle-#{@jsbundle.hash}.js")).should > 0
    end
    
    it 'stores stylesheets in a single CSS file' do
      File.size(File.join(@storage.dir, "rack-bundle-#{@cssbundle.hash}.css")).should > 0
    end
  end
end