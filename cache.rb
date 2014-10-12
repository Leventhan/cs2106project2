#!/usr/bin/env ruby
require 'lrucache'

class Cache
  def initialize
    @cache = LRUCache.new(:max_size => 4)
  end

  def in_cache?(elem)
    elements.include? elem
  end

  def fetch(s, p)
    @cache.fetch("#{s} #{p}")
  end

  def store(s, p, pt_entry)
    @cache.store("#{s} #{p}", pt_entry)
  end

  def elements
    @cache.keys
  end

end