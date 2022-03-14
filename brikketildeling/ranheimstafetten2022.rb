#!/usr/bin/env ruby
require './brikke_tildeling.rb'
bt = BrikkeTildeling.new 'config2022.yml'
bt.clean_emit_tags
bt.assign_rental_tags
bt.total_teams
bt.write_xml

