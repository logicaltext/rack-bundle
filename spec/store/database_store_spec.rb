require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Rack::Bundle::DatabaseStore do  
  before do
    ENV['DATABASE_URL'] = "sqlite://#{Dir.tmpdir}/foo.db"
    @db_store = Rack::Bundle::DatabaseStore.new
    `mkdir tmp`
  end

  after(:each) do
    `rm -rf tmp`
  end
  
  context 'initializing' do
    it 'looks for a DATABASE_URL environment variable when a database URL is not specified' do
      @db_store.db.url.should == "sqlite:/#{Dir.tmpdir}/foo.db"
    end
    it 'takes a database url as a parameter' do
      db_store = Rack::Bundle::DatabaseStore.new "sqlite://#{Dir.tmpdir}/bar.db"
      db_store.db.url.should == "sqlite:/#{Dir.tmpdir}/bar.db"
    end
    it 'creates a table to store bundles in' do
      @db_store.db.tables.should include(:rack_bundle)
    end
  end
  
  context '#find_bundle_file_by_hash' do
    it 'takes a bundle hash as argument and returns a path to a matching bundle file' do
      jquery_file  = File.join(FIXTURES_PATH, 'jquery-1.4.1.min.js')
      mylib_file   = File.join(FIXTURES_PATH, 'mylib.js')
      @files       = [jquery_file, mylib_file]
      jsbundle     = Rack::Bundle::JSBundle.new *@files
      @db_store.db[:rack_bundle].insert(:hash => jsbundle.hash, :contents => jsbundle.contents, :type => 'js')
      expected = "./tmp/rack-bundle-#{jsbundle.hash}.js"
      @db_store.find_bundle_file_by_hash(jsbundle.hash).should == expected
    end

    it "returns nil when a bundle can't be found with a matching hash" do
      @db_store.find_bundle_file_by_hash('non existant').should be_nil
    end
  end

  it "saves bundles to the database on #add" do
    jsbundle = make_js_bundle
    @db_store.add jsbundle
    @db_store.db[:rack_bundle].where(:hash => jsbundle.hash).first[:hash].should == jsbundle.hash
  end
end