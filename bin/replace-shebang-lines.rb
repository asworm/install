#!/usr/bin/env ruby

directory_arg = ARGV[0]

if !directory_arg
  puts "Usage: bin/#{__FILE__.split("/").last} [directory]"
  exit 1
end

directory_arg = File.expand_path(directory_arg)

if !File.exist?(directory_arg)
  puts "Directory does not exist at path:"
  puts "  #{directory_arg}"
  exit 1
end

if !File.directory?(directory_arg)
  puts "Path passed as first argument is not a directory:"
  puts "  #{directory_arg}"
  exit 1
end

def is_shebang_line?(line)
  line.start_with?("#!")
end

def line_needs_rewrite?(line)
  is_shebang_line?(line) && line[/ruby/] && line != "#!/usr/bin/env ruby"
end

def file_needs_shebang_rewrite(file)
  return false if File.directory?(file)
  return false if file[/bundler\/templates\/Executable/]
  return false if file[/rubygems\/commands\/setup_command.rb/]
  return false if file[/test\/rubygems\/test_gem_installer.rb/]
  return false if File.extname(file) == ".gem"
  return false if File.extname(file) == ".ri"
  return false if File.extname(file) == ".bundle"
  return false if File.extname(file) == ".jar"
  return false if File.extname(file) == ".apk"
  return false if File.extname(file) == ".dylib"
  return false if File.extname(file) == ".gemspec"

  begin
    contents = File.read(file, encoding: "UTF-8")
    lines = contents.split($-0)
    needs_shebang_rewrite = false
    index = 0
    lines.each do |line|
      if line_needs_rewrite?(line)
        needs_shebang_rewrite = true
        break
      end
      index = index + 1
    end

    if needs_shebang_rewrite
      return lines, index
    else
      return false, -1
    end
  rescue ArgumentError => e
    if e.message == "invalid byte sequence in UTF-8"
    else
      raise e, e.message
    end
  end
end

Dir.glob(File.join(directory_arg, "**", "*")).each do |file|
  lines, index = file_needs_shebang_rewrite(file)
  if lines
    puts "File needs shebang rewrite: #{file}"
    puts "                          : #{lines[index]}"
    lines[index] = "#!/usr/bin/env ruby"
    File.open(file, "w:UTF-8") do |file_for_writing|
      lines.each { |line| file_for_writing.puts(line) }
    end
  end
end
