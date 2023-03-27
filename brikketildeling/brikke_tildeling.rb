require 'nokogiri'
require 'fileutils'
require 'date'
require 'yaml'

class Array
  def find_duplicates
    select.with_index do |e, i|
      i != self.index(e)
    end
  end
end

class BrikkeTildeling
  attr_accessor :xml_document, :xml_file, :tag_id, :config

  def initialize(config_filename)
    if config_filename
      @config = YAML.load_file(config_filename)
      pp @config
      @tag_id = @config['series']['start']
      File.open(@config['filename'], 'r:ISO-8859-10') do |f|
        @xml_file = @config['filename'] + "#{DateTime.now().strftime("%Y%m%d%H%M%S")}.tags"
        @xml_document = Nokogiri::XML(f, nil, 'ISO-8859-10') { |x| x.noblanks }
      end
      #puts "Initialized"
      #puts @xml_document.to_xml
    else
      puts "Please provide the name of a config file in the yaml format (see README for details)."
    end
  end

  def run
    assign = should_reassign?
    if assign
      puts "Reassigning tags."
      clean_emit_tags
      assign_rental_tags
      write_xml
      puts "Next tag id: #{@tag_id}."
    else
      puts "Keeping exisiting tags."
    end
    status
  end


  private

  def should_reassign?
    valid_answer = false
    while !valid_answer do
      puts "Do you want to reassign all tags in the file (yes/no)?"
      answer = gets.chomp
      puts answer.downcase
      valid_answer = ["yes", "y", "no", "n"].include? answer.downcase
    end
    answer == "yes" || answer == "y"
  end

  # Will delete all registered emit tags below the configured end of series
  # Does not consider start of series... This is probably a BUG!
  def clean_emit_tags
    people = @xml_document.xpath('//Person')
    people.each do |person|
      clear_emit_tag(person)
      clear_chip_tag(person)
    end
  end

  def klass_short_name(entry)
    klass = entry > 'EntryClass'
    klass[0]['shortName']
  end

  def assign_rental_tags
    entries = @xml_document.xpath('//Entry')
    entries.each do |entry|
      next if entry.content.empty?
      short_name = klass_short_name entry
      assign_tags(entry) unless @config['exceptions'].include?(short_name)
    end
  end

  def status
    duplicates
    team_status
    total_teams
  end

  def duplicates
    competitors = @xml_document.xpath('//TeamEntry//Competitor')
    competitors = competitors.map {|e| e['competitorId']}
    puts "Total number of competitors: #{competitors.count}"
    puts "Duplicate competitors: #{competitors.find_duplicates}"
  end

  def team_status
    entries = @xml_document.xpath('//Entry')
    entries.each do |entry|
      next if entry.content.empty?
      teams = entry > 'TeamEntry'
      short_name = klass_short_name entry
      puts "#{short_name} - #{teams.count} teams"
    end
  end

  def total_teams
    teams = @xml_document.xpath('//TeamEntry')
    puts "Total teams: #{teams.count}."
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
    @tag_id += 1 if @config['series']['missing'].include?(@tag_id)
  end

  def emit_tag(person)
    emit = person > 'Emit'
    emit[0]
  end

  def clear_emit_tag(person)
    emit = emit_tag(person)
    emit.content = nil if !emit.content.empty? && emit.content.to_i < @config['series']['end']
  end

  def chip_tag(person)
    chip = person > 'ChipNumber'
    chip[0]
  end

  def clear_chip_tag(person)
    chip = chip_tag(person)
    chip.content = nil if !chip.content.empty? && chip.content.to_i < @config['series']['end']
  end

  def write_xml
    # FileUtils.cp(@xml_file, @xml_file + '.bak')
    puts "Writing to #{@xml_file}."
    File.open(@xml_file, 'w') do |f|
      f.write(@xml_document.to_xml)
    end
  end
end
