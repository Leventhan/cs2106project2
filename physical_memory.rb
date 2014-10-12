#!/usr/bin/env ruby
load 'cache.rb'
load 'segment_table.rb'
load 'page_table.rb'
load 'page.rb'
load 'virtual_address.rb'

class PhysicalMemory
  attr_accessor :memory, :count, :bitmap, :segment_table

  def initialize
    @memory = Array.new(1024)
    @count = 0 # Count of filled frames
    @bitmap = Array.new(1024, 0) # initialize bitmap
    @segment_table = SegmentTable.new
    append_frame(@segment_table) # Allocate first frame to segment table
  end

  def translate_virtual_addresses_with_lru(input_string)
    args = input_string.split(" ")
    raise Exception.new("Odd number of Segment Table initialization string!") if args.size.odd?
    results = []

    cache = Cache.new

    (args.size/2).times do |index|
      op = args[(index*2)].to_i
      virtual_address = args[(index*2)+1].to_i

      if op == 0
        results = results + read_virtual_address_with_lru(virtual_address, cache)
      elsif op == 1
        results = results + write_virtual_address_with_lru(virtual_address, cache)
      else
        raise Exception.new("op must be either 0(read) or 1(write)")
      end
    end
    return results
  end

  def read_virtual_address_with_lru(virtual_address, cache)
    v = VirtualAddress.new(virtual_address)
    # p "Reading #{virtual_address} #{v.binary_string} #{v.segment} #{v.page} #{v.w}"

    hit_or_miss = ""
    pt_entry = cache.fetch(v.segment, v.page)
    # p "Fetched pt entry: #{pt_entry}, nil?: #{pt_entry.nil?}"

    if pt_entry.nil?
      hit_or_miss = "m"

      st_entry = @segment_table.entries[v.segment]
      return ["pf"] if st_entry == -1
      return ["err"] if st_entry == 0

      pt_address = @segment_table.entries[v.segment]
      page_table = get_frame(pt_address)
      pt_entry = page_table.entries[v.page]
    else
      hit_or_miss = "h"
    end

    return ["pf"] if pt_entry == -1
    return ["err"] if pt_entry == 0

    return [hit_or_miss, pt_entry + v.w]
  end

  def write_virtual_address_with_lru(virtual_address, cache)
    v = VirtualAddress.new(virtual_address)
    # p "Writing #{virtual_address} #{v.binary_string} #{v.segment} #{v.page} #{v.w}"

    hit_or_miss = ""
    pt_entry = cache.fetch(v.segment, v.page)
    # p "Fetched pt entry: #{pt_entry}, nil?: #{pt_entry.nil?}"

    if pt_entry.nil?
      hit_or_miss = "m"

      st_entry = @segment_table.entries[v.segment]
      # p "(ST entry = #{st_entry})"
      return ["pf"] if st_entry == -1
      pt_address = st_entry
      if st_entry == 0
        pt_address = get_free_physical_address(PageTable.new)
        insert_pt_of_segment_at_physical_address(v.segment, pt_address)
      end

      page_table = get_frame(pt_address)
      pt_entry = page_table.entries[v.page]
    else
      hit_or_miss = "h"
    end

    # p "(PT entry = #{pt_entry})"
    if pt_entry == 0
      page_address = get_free_physical_address(Page.new)
      insert_page_of_segment_at_physical_address(v.page, v.segment, page_address)
      return [hit_or_miss, page_address + v.w]
    else
      return ["pf"] if pt_entry == -1
      return [hit_or_miss, pt_entry + v.w]
    end
  end

  def translate_virtual_addresses(input_string)
    args = input_string.split(" ")
    raise Exception.new("Odd number of Segment Table initialization string!") if args.size.odd?

    results = []
    (args.size/2).times do |index|
      op = args[(index*2)].to_i
      virtual_address = args[(index*2)+1].to_i

      if op == 0
        results << read_virtual_address(virtual_address)
      elsif op == 1
        results << write_virtual_address(virtual_address)
      else
        raise Exception.new("op must be either 0(read) or 1(write)")
      end
    end

    return results
  end

  def read_virtual_address(virtual_address)
    v = VirtualAddress.new(virtual_address)
    # p "Reading #{virtual_address} #{v.binary_string} #{v.segment} #{v.page} #{v.w}"
    st_entry = @segment_table.entries[v.segment]
    # p "(ST entry = #{st_entry})"
    return "pf" if st_entry == -1
    return "err" if st_entry == 0

    pt_address = @segment_table.entries[v.segment]
    page_table = get_frame(pt_address)
    pt_entry = page_table.entries[v.page]
    # p "(PT entry = #{pt_entry})"
    return "pf" if pt_entry == -1
    return "err" if pt_entry == 0

    return pt_entry + v.w
  end

  def write_virtual_address(virtual_address)
    v = VirtualAddress.new(virtual_address)
    p "Writing #{virtual_address} #{v.binary_string} #{v.segment} #{v.page} #{v.w}"
    st_entry = @segment_table.entries[v.segment]
    p "(ST entry = #{st_entry})"
    return "pf" if st_entry == -1
    pt_address = st_entry
    if st_entry == 0
      pt_address = get_free_physical_address(PageTable.new)
      insert_pt_of_segment_at_physical_address(v.segment, pt_address)
    end

    page_table = get_frame(pt_address)
    pt_entry = page_table.entries[v.page]
    p "(PT entry = #{pt_entry})"
    if pt_entry == 0
      page_address = get_free_physical_address(Page.new)
      insert_page_of_segment_at_physical_address(v.page, v.segment, page_address)
      return page_address + v.w
    else
      return "pf" if pt_entry == -1
      return pt_entry + v.w
    end
  end

  def initialize_segment_table(input_string)
    # For example, 15 512 means that the PT of segment 15 starts at address 512 (in terms of PM frames, starts at frame 1)
    args = input_string.split(" ")
    raise Exception.new("Odd number of Segment Table initialization string!") if args.size.odd?
    (args.size/2).times do |index|
      segment = args[(index*2)].to_i
      physical_address = args[(index*2)+1].to_i
      insert_pt_of_segment_at_physical_address(segment, physical_address)
    end
  end

  def insert_pt_of_segment_at_physical_address(segment, physical_address)
      # p "Set PT of segment #{segment} to start at #{physical_address}"
      @segment_table.entries[segment] = physical_address
      set_frame(physical_address, PageTable.new) if physical_address != -1
  end

  def initialize_page_tables(input_string)
    # For example, 7 13 4096 means that page 7 of segment 13 starts at address 4096. That is, PT[ST[13]+7] = 4096.
    args = input_string.split(" ")
    raise Exception.new("Number of Page Table initialization string not a multiple of three!") if args.size % 3 != 0
    (args.size/3).times do |index|
      page = args[(index*3)].to_i
      segment = args[(index*3)+1].to_i
      page_address = args[(index*3)+2].to_i

      insert_page_of_segment_at_physical_address(page, segment, page_address)
    end
  end

  def insert_page_of_segment_at_physical_address(page, segment, physical_address)
    raise Exception.new("Page Table for segment #{segment} does not exist") if @segment_table.entries[segment] == 0

    pt_address = @segment_table.entries[segment]
    # p "Set Page #{page} of segment #{segment} (PT address #{pt_address}) to start at #{physical_address}"
    page_table = get_frame(pt_address)
    page_table.entries[page] = physical_address
    set_frame(physical_address, Page.new) if physical_address != -1
  end

  def get_free_physical_address(f)
    return frame_id_to_physical_address(get_free_frame_id(f))
  end

  def get_free_frame_id(f)
    frame_id = -1
    if f.is_a?(Page)
      @bitmap.each do |bit|
        frame_id +=1
        # p "checking bit #{bit} at frame #{frame_id} == 0 ? => #{bit == 0} "
        return frame_id if bit == 0
      end
    elsif f.is_a?(PageTable)
      @bitmap.each do |bit|
        frame_id +=1
        return frame_id if bit == 0 && @bitmap[frame_id+1] == 0 # finds two consecutive free frames
      end
    end
  end

  def append_frame(f)
    if f.is_a?(SegmentTable)
      free_frame_id = @count
    else
      free_frame_id = get_free_frame_id(f)
    end
    start_address = frame_id_to_physical_address(free_frame_id)
    set_frame(start_address, f)
  end

  def get_frame(physical_address)
    frame_id = physical_address_to_frame_id(physical_address)
    return @memory[frame_id]
  end

  # Sets content of PM at frame_id as f
  def set_frame(physical_address, f)
    unless f.is_a?(SegmentTable) || f.is_a?(PageTable) || f.is_a?(Page)
      raise Exception.new("Frame must be either a SegmentTable, PageTable, or Page")
    end

    frame_id = physical_address_to_frame_id(physical_address)
    if f.is_a?(SegmentTable) || f.is_a?(Page)
      fill_frame(frame_id, f)
    elsif f.is_a?(PageTable)
      fill_frame(frame_id, f)
      fill_frame(frame_id+1, f)
    end
  end

  def fill_frame(frame_id, f)
    raise Exception.new("Frame #{frame_id} is already filled with: #{@memory[frame_id]}") if (@bitmap[frame_id] == 1)
    @memory[frame_id] = f
    @bitmap[frame_id] = 1
    @count+=1
  end

  def physical_address_to_frame_id(addr)
    raise Exception.new("Physical address not a multiple of 512!") if addr % 512 != 0
    return addr / 512
  end

  def frame_id_to_physical_address(id)
    raise Exception.new("Physical memory only has frame ids 0...1023") if id > 1023
    return id * 512
  end

end
