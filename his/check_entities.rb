# Open Files for reading and output
entities = File.open('entities.txt', 'r') {|f| f.readlines}
details = File.open('doctordetails.txt', 'r') {|f| f.readlines}
missing_entities = File.open('missing_entities.txt', 'a')
error_log = File.open('errorlog2.txt', 'a')

entities_length = entities.length
details_length = details.length

# Variables needed to hold the entities from the two different files
detail_entities = []

for i in 0..details_length
  if i % 2 == 1
    if details[i] =~ /\t(.+?)\t\t.+$/
      detail_entities << $1
    else
      # 0 instances when run
      error_log.puts "Line #{i} did not match expected regexp"
    end
  end
end

detail_entities_length = detail_entities.length

for i in 0...entities_length
  match = false
  for j in 0...detail_entities_length
    if match_data = entities[i].match(detail_entities[j])
      match = true
    end
  end
  unless match
    missing_entities.puts entities[i]
  end
end

missing_entities.close
error_log.close
