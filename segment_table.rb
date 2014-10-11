#!/usr/bin/env ruby

# Each entry of the ST can have three types of entry:

# * ‒1 means the PT is currently not resident in physical memory. This would results in a page fault and the missing PT would be loaded from the disk. In this project we are not managing the disk and hence only a message will be generated.

# 0 means the corresponding PT does not exist. Consequently, a read access results in an error. A write access causes the creation of a new blank PT.

# a positive integer, f, means that the PT starts at physical address f (multiples of 512)


#### Input string
# s1 f1 s2 f2 … sn fn
# Each pair si fi means that the PT of segment si starts at address fi.
# For example, 15 512 means that the PT of segment 15 starts at address 512. That is, ST[15] = 512. Similarly, 9 ‒1 means that the PT of segment 9 is not resident. That is, ST[9] = ‒1

class SegmentTable
  attr_accessor :entries

  def initialize
    @entries = Array.new(512, 0)
  end
end
