#!/usr/bin/env ruby

# Each entry of a PT can have three types of entry:

# ‒1 means the page is currently not resident in PM. Similar to a missing PT, a message is generated.

# 0 means the corresponding page does not exist. A read access results in an error. A write access causes the allocation of a new blank page.

# a positive integer, f, means that the page starts at physical address f .

class PageTable
  attr_accessor :entries

  def initialize
    @entries = Array.new(1024, 0)
  end
end
