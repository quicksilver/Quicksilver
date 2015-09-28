#!/usr/bin/env ruby -W
# encoding: utf-8

require 'set'

changed_lines = `git diff $TRAVIS_COMMIT_RANGE -- *.[mh]`.split("\n").select { |l| l.start_with? "+" }

changed_lines.each do |line|
	if /^\+ /.match(line) then
		puts "Invalid line #{line}"
		exit 1
	end
end

