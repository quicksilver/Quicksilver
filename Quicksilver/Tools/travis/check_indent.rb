#!/usr/bin/env ruby -W
# encoding: utf-8

require 'set'

commit_range = ENV['TRAVIS_COMMIT_RANGE'] || 'master'

changed_lines = `git diff #{commit_range} -- *.[mh]`.split("\n").select { |l| l.start_with? "+" }

comment_block = false

invalid_lines = []
changed_lines.each do |line|
	if /^\+ /.match(line) and not comment_block then
		invalid_lines << line
	elsif /^\+\s*?\/\*\*/.match(line) then
		comment_block = true
	elsif /^\+\s*?\*\*\//.match(line) then
		comment_block = false
	end
end

exit 0 if invalid_lines.empty?
puts "Invalid lines:"
invalid_lines.each do |line|
	puts line
end