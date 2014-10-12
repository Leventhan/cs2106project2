#!/usr/bin/env ruby
require 'lrucache'

class Cache
  def initialize
    @cache = LRUCache.new(:max_size => 4,
                          :eviction_handler => lambda { |value| p "#{value} was evicted!" })
  end

  def in_cache?(elem)
    elements.include? elem
  end

  def store(elem)
    @cache.store(elem, elem)
  end

  def elements
    @cache.keys
  end

end