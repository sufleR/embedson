[![Gem Version](https://badge.fury.io/rb/embedson.svg)](http://badge.fury.io/rb/embedson)
[![Dependency Status](https://gemnasium.com/sufleR/embedson.svg)](https://gemnasium.com/sufleR/embedson)
[![Code Climate](https://codeclimate.com/github/sufleR/embedson/badges/gpa.svg)](https://codeclimate.com/github/sufleR/embedson)
[![Test Coverage](https://codeclimate.com/github/sufleR/embedson/badges/coverage.svg)](https://codeclimate.com/github/sufleR/embedson)
[![Build Status](https://travis-ci.org/sufleR/embedson.svg?branch=master)](https://travis-ci.org/sufleR/embedson)

# Embedson

Adds functionality of `embeds_one` to ActiveRecord.

Adds functionality of `embedded_in` to any class:

- with defined `to_h` method which should return `Hash` 
- initialized with Hash.

Result of `to_h` is saved json/hstore column.


## Installation

Add this line to your application's Gemfile:

    gem 'embedson'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install embedson

## Usage

Example with [Searchlight](https://github.com/nathanl/searchlight) is described
in blogpost ["Persistent queries in Ruby on Rails with PostgreSQL"](https://netguru.co/blog/persistent-queries-in-ruby-on-rails).

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

	  embeds_one :virt, class_name: Virt,
                        column_name: :data,
                        inverse_of: :parent,
                        hash_method: :to_h    # default option
	end

	class Virt
	  include Virtus.model
	  extend Embedson::Model

	  attribute :name, String
	  attribute :address, Hash

	  embedded_in :parent, class_name: Test, inverse_of: :virt
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

You don't have to use all options to define ```embeds_one``` and ```embedded_in```. Just name it with downcased related class name.


```RUBY
	#create_tests.rb - migration
	class CreateTests < ActiveRecord::Migration
	  def change
	    create_table :tests do |t|
	      t.json :virt
	    end
	  end
	end

	class Test < ActiveRecord::Base

	  embeds_one :virt
	end

	class Virt
	  include Virtus.model
	  extend Embedson::Model

	  attribute :name, String
	  attribute :address, Hash

	  embedded_in :test
	end
```

### Additional methods in embedded model:

- ####save
	Assigns ```to_h``` result to parent and saves it with ```save```.

- ####save!
	Assigns ```to_h``` result to parent and saves it with ```save!```.

- ####destroy
	Assigns ```nil``` to parent and saves it with ```save!```

- ####embedson_model_changed!
	This gem does not provide dirty tracking of embedded model. To register change in parent model use this method in your setter.


```RUBY

	def your_variable=(arg)
	  @your_variable = arg
	  embedson_model_changed!
	end

```

## Known issues

- Placing ```initialize``` method after ```embedded_in``` and using ```Emb.new(parent: parent)```

These examples will work:

```RUBY
	class Emb
	  extend Embedson::Model

	  def initialize(attributes = {})
	    # do your work here
	  end

	  embedded_in :parent
	end
```

```RUBY
	class Emb
	  extend Embedson::Model

	  embedded_in :parent

	  def initialize(attributes = {})
	    self.parent = attributes[:parent]
	    # do your work here
	  end
	end
``` 

This will **not** work!

```RUBY
	class Emb
	  extend Embedson::Model
	  embedded_in :parent

	  def initialize(attributes = {})
	    # if you forget about assigning parent
	    # do your work here
	  end
	end

```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/embedson/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Copyright (c) 2014 Szymon Frącczak. See LICENSE.txt for further details.
