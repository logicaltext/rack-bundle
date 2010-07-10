require 'sequel'

class Rack::Bundle::DatabaseStore
  attr_accessor :db, :bundles
  
  def initialize url = ENV['DATABASE_URL']
    @db = Sequel.connect(url)
    create_table!
  end
  
  def find_bundle_file_by_hash hash
    return nil unless result = @db[:rack_bundle].where(:hash => hash).first
    filename = "./tmp/rack-bundle-#{result[:hash]}.#{result[:type]}"
    File.open(filename, 'w') { |file| file << result[:contents] }
    filename
  end
  
  def add bundle
    return false if has_bundle? bundle
    @db[:rack_bundle].insert :contents => bundle.contents, 
      :hash => bundle.hash,
      :type => bundle.is_a?(Rack::Bundle::JSBundle) ? 'js' : 'css'
  end
  
  def has_bundle? bundle
    not @db[:rack_bundle].where(:hash => hash).empty?
  end
    
  private  
  def create_table!
    @db.create_table! 'rack_bundle' do
      String  :hash
      String  :type
      Text    :contents
      
      index   :hash
    end
  end
end