load 'physical_memory.rb'

p = PhysicalMemory.new

File.open(ARGV[0], "r") do |file|
  line = file.gets
  p.initialize_segment_table(line)

  line = file.gets
  p.initialize_page_tables(line)
end

# TODO: open second file




