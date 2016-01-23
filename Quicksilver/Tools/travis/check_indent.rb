#!/usr/bin/env ruby -W
# encoding: utf-8

require 'set'

changed_lines = `git diff $TRAVIS_COMMIT_RANGE -- *.[mh]`.split("\n").select { |l| l.start_with? "+" }

comment_block = false

changed_lines.each do |line|
	if /^\+ /.match(line) and not comment_block then
		puts "Invalid line #{line}"
		exit 1
	elsif /^\+\s*?\/\*\*/.match(line) then
		comment_block = true
	elsif /^\+\s*?\*\*\//.match(line) then
		comment_block = false
	end
end

