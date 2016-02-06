#!/usr/bin/env ruby -W
# encoding: utf-8

require 'set'

commit_range = ENV['TRAVIS_COMMIT_RANGE'] || 'master..HEAD'

puts "#{File.basename($0)}: commit range #{commit_range}"

invalid_files = {}
comment_block = false
last_file = nil
last_lines = nil
changed_lines = `git diff #{commit_range} -- *.[mh]`.lines
changed_lines.each do |line|
	case line
	when /^\+\+\+ [^\/]+\/(.*)$/
		last_file = $1
	when /^@@ ([-+]\d*,\d*) ([-+]\d*,\d*) @@/
		last_lines = [$1, $2]
	when /^\+ /
		invalid_files[last_file] ||= {}
		invalid_files[last_file][last_lines] ||= []
		invalid_files[last_file][last_lines] << line unless comment_block
	when /^\+\s*?\/\*\*/
		comment_block = true
	when /^\+\s*?\*\*\// then
		comment_block = false
	end
end

if invalid_files.empty?
	puts "All indent correct!"
	exit 0
end

puts "The following files have incorrect indent:"
invalid_files.each do |file, lines|
	puts "• #{file}:"
	lines.each do |line_no, lines|
		puts "around #{line_no[0]}..#{line_no[1]}:"
		lines.each do |line|
			puts line
		end
	end
end