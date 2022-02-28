require 'nokogiri'
require 'fileutils'
require 'date'

class BrikkeTildeling
  attr_accessor :xml_document, :xml_file, :tag_id

  def initialize(filename)
    @tag_id = 1001
    File.open(filename) do |f|
      @xml_file = filename + "#{DateTime.now().strftime("%Y%m%d%H%M%S")}.tags"
      @xml_document = Nokogiri::XML(f) { |x| x.noblanks }
    end
  end

  # Will delete all registered emit tags below 1250
  def clean_emit_tags
    people = @xml_document.xpath('//Person')
    people.each do |person|
      clear_emit_tag(person)
      clear_chip_tag(person)
    end
  end

  def assign_rental_tags
    entries = @xml_document.xpath('//Entry')
    entries.each do |entry|
      next if entry.content.empty?

      klass = entry > 'EntryClass'
      short_name = klass[0]['shortName']
      teams = entry > 'TeamEntry'
      puts "#{short_name} - #{teams.count} teams"
      assign_tags(entry) unless ['G 8-10', 'J 8-10'].include?(short_name)
    end
    puts "Next tag id: #{@tag_id}."
    # puts @xml_document.to_xml
  end

  def total_teams
    teams = @xml_document.xpath('//TeamEntry')
    puts "Total teams: #{teams.count}"
  end

  def assign_tags(entry)
    contestants = entry.xpath('.//Person')
    contestants.each do |person|
      update_tags(person)
    end
  end

  def update_tags(person)
    emit = emit_tag(person)
    chip = chip_tag(person)
    return unless emit.content.empty? && chip.content.empty?

    skip_missing_or_defect_tags
    emit.content = @tag_id
    chip.content = @tag_id
    @tag_id += 1
  end

  def number_of_teams

  end

  def skip_missing_or_defect_tags
    @tag_id += 1 if [1101, 1102, 1131].include?(@tag_id)
  end

  def emit_tag(person)
    emit = person > 'Emit'
    emit[0]
  end

  def clear_emit_tag(person)
    emit = emit_tag(person)
    emit.content = nil if !emit.content.empty? && emit.content.to_i < 1250
  end

  def chip_tag(person)
    chip = person > 'ChipNumber'
    chip[0]
  end

  def clear_chip_tag(person)
    chip = chip_tag(person)
    chip.content = nil if !chip.content.empty? && chip.content.to_i < 1250
  end

  def write_xml
    # FileUtils.cp(@xml_file, @xml_file + '.bak')
    puts "Writing to #{@xml_file}."
    File.open(@xml_file, 'w') do |f|
      f.write(@xml_document.to_xml)
    end
  end
end

#puts DateTime.now().strftime("%Y%m%d%H%M%S")
brikke_tildeling = BrikkeTildeling.new './SSF XML_eventid_330476.xml'
brikke_tildeling.clean_emit_tags
brikke_tildeling.assign_rental_tags
brikke_tildeling.total_teams
brikke_tildeling.write_xml