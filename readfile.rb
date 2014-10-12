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
  # results = p.translate_virtual_addresses(line)
  # p results.join(" ")

  results2 = p.translate_virtual_addresses_with_lru(line)
  p results2.join(" ")

  # destination_path = File.dirname(input_path)+ "/A0099317U.txt"
  # File.open(destination_path, 'a') { |file| file.write(results.join(" "))}
  # File.open(destination_path, 'a') { |file| file.write(results2.join(" "))}
end
