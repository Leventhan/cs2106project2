#!/usr/bin/env ruby

# A virtual address (VA) is assumed to be an integer and thus comprises 32 bits. These are divided into three components: the segment number, s, the page number, p, and the offset within the page, w. The sizes (in bits) of the three components are as follows:
# |s| = 9, |p| = 10, |w| = 9
# The leading 4 bits of the VA are unused.

class VirtualAddress
  attr_accessor :integer, :binary_string, :s, :p, :w

  def initialize(i)
    @integer = i
    @binary_string = i.to_s(2).rjust(29, "0")
    @s = @binary_string.slice(0, 9).to_i(2)
    @p = @binary_string.slice(10, 10).to_i(2)
    @w = @binary_string.slice(19, 9).to_i(2)
  end
end