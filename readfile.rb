load 'physical_memory.rb'

p = PhysicalMemory.new

File.open(ARGV[0], "r") do |file|
  line = file.gets
  p.initialize_segment_table(line)

  line = file.gets
  p.initialize_page_tables(line)
end

File.open(ARGV[1], "r") do |file|
  line = file.gets
  results = p.translate_virtual_addresses(line)
  p results.join(" ")
end
