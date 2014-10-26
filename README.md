[![Gem Version](https://badge.fury.io/rb/embedson.svg)](http://badge.fury.io/rb/embedson)
[![Dependency Status](https://gemnasium.com/sufleR/embedson.svg)](https://gemnasium.com/sufleR/embedson)
[![Code Climate](https://codeclimate.com/github/sufleR/embedson/badges/gpa.svg)](https://codeclimate.com/github/sufleR/embedson)
[![Test Coverage](https://codeclimate.com/github/sufleR/embedson/badges/coverage.svg)](https://codeclimate.com/github/sufleR/embedson)
[![Build Status](https://travis-ci.org/sufleR/embedson.svg?branch=master)](https://travis-ci.org/sufleR/embedson)

# Embedson

Adds functionality of `embedded_one` and `embedded_in`. 

Embeded class is saved in json column and has to provide `to_h` method which should return `Hash` to store in database.

####TODO

1. Options and methods documentation

## Installation

Add this line to your application's Gemfile:

    gem 'embedson'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install embedson

## Usage

Example with [Virtus](https://github.com/solnic/virtus):

```RUBY
	
	#create_tests.rb - migration	
	class CreateTests < ActiveRecord::Migration
	  def change
	    create_table :tests do |t|
		  t.json :data
		end
	  end
	end
	
	class Test < ActiveRecord::Base
 
	  embeds_one :virt, column_name: :data, inverse_of: :parent
	end

	class Virt
	  include Virtus.model
	  extend Embedson::Model
 
	  attribute :name, String
	  attribute :address, Hash
	
	  embedded_in :parent, class_name: Test
	end
	
	virt = Virt.new(name: 'Sample', address: { street: 'Kind', number: '33' })
	virt.attributes # => {:name=>"Sample", :address=>{:street=>"Kind", :number=>"33"}}
	
	test = Test.create!
	test.attributes # => {"id"=>1, "data"=>nil}
	
	test.virt = virt
	test.save
	test.attributes # => {"id"=>1, "data"=>{"name"=>"Sample", "address"=>{"street"=>"Kind", "number"=>"33"}}
	
	test.reload.virt.attributes # =>  {:name=>"Sample", :address=>{:street=>"Kind", :number=>"33"}}
	test.virt == virt # => true
	test.virt.parent == test # => true
	
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/embedson/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

