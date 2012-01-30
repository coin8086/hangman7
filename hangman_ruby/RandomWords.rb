require 'set'

if ARGV.size < 1 then
  $stderr << "A number of random words is expected but missing.\n"
  exit(false)
end

DICT_FILE = ENV['hangman_dict'] || 'words.txt'

dict = []
begin
  File.open(DICT_FILE, 'rb') do |f|
    f.each_line do |line|
      word = line.chomp
      dict << word if word.size > 0
    end
  end
rescue SystemCallError
  $stderr << "Cannot open dictionary file '%s' for reading!\n" % DICT_FILE
  exit(false)
end

count = nil
if (count = ARGV[0].to_i) < 1 || count > dict.size then
  $stderr << "%s is not a number, or its value is out of [1, %d]\n" % [ARGV[0], dict.size]
  exit(false)
end

out = Set.new
size = dict.size
r = Random.new(Time.now.to_i)
i = count
while i >= 1 do
  idx = (r.rand(size) * 10 + r.rand(size) + Integer(r.rand(size) / (r.rand(size) + 1))) % size
  if out.add?(idx) then
    $stdout << dict[idx].upcase << "\n"
    i -= 1
  end
end
