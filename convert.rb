puts '= convert RE:View'
Dir.glob('./chapters/*.md').each do |markdown_file|
  puts "== #{markdown_file}"
  review_file = markdown_file.gsub('chapters', 'reviews').gsub('.md', '.re')
  system("md2review --render-enable-cmd #{markdown_file} > #{review_file}")
end
puts "= convert PDF"
system('cd ./reviews;rake pdf')