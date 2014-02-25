require 'rtesseract'

class GrepimgText < Struct.new(:filename, :text)
end

class GrepimgCli
  attr_writer :ocr_engine, :image_resize_factor
  attr_accessor :argv, :input, :pattern, :file_mask
  attr_accessor :matcher, :is_case_insensitive

  def initialize
    self.matcher = :match_text
  end

  def run(argv, input = [])
    self.argv = argv
    self.input = input
    parse_args
    find_matches
  end

protected
  def ocr_engine
    return @ocr_engine if @ocr_engine

    @ocr_engine = RTesseract
    @ocr_engine.new # Fixes a bug in the gem where the dependency RMagick isn't being loaded
    @ocr_engine
  end

  def image_resize_factor
    @image_resize_factor ||= 3
  end

  def new_text
    GrepimgText.new
  end

  def filters
    @filters ||= []
  end

  def parse_args
    self.file_mask = input unless input.empty?

    argv.each do |arg|
      case arg
        when '-i'
          self.is_case_insensitive = true

        when '-e'
          self.matcher = :match_regex

        else
          push_param(arg)
      end
    end
  end

  def push_param(param)
    unless @first_param_pushed
      self.pattern = param
      @first_param_pushed = true
    else
      if file_mask
        file_mask << param
      else
        self.file_mask = [param]
      end
    end
  end

  def image_text(filename)
    ocr_image = ocr_engine.read(filename) do |image|
      image.resize!(image_resize_factor) if image_resize_factor > 0
    end
    ocr_image.to_s
  end

  def each_file_text
    Dir.glob(file_mask) do |filename|
      begin
        image_text(filename).split("\n").each do |line|
          file_text = new_text

          file_text.filename = filename
          file_text.text = line

          yield file_text
        end
      rescue Magick::ImageMagickError
        next
      end
    end
  end

  def find_matches
    each_file_text do |file_text|
      output_match file_text if send(matcher, file_text.text)
    end
  end

  def output_match(file_text)
    puts "File: #{file_text.filename}, Text: \n#{file_text.text}\n\n"
  end

  def match_text(text)
    if is_case_insensitive
      text = text.downcase
      self.pattern = pattern.downcase
    end

    text.include? pattern
  end

  def match_regex(text)
    if is_case_insensitive
      text =~ /#{pattern}/i
    else
      text =~ /#{pattern}/
    end
  end
end

grepimg = GrepimgCli.new
grepimg.run(ARGV, STDIN.tty? ? [] : STDIN.readlines.map(&:strip))
