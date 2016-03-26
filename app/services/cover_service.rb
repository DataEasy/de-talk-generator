require 'fileutils'

class CoverService
  SVG_TEMPLATE_APTH = Rails.root.join('app', 'assets', 'images', 'Template_DE_Talks.svg')
  COVER_DESTINY_FOLDER = Rails.root.join('public', 'images')

  def publish_cover(talk)
    filename = create_cover(talk)

    tmp_png_path = get_temp_path_for "#{filename}.png"
    cover_path = Rails.root.join(COVER_DESTINY_FOLDER,  "#{talk.title_for_cover_filename}.png")

    FileUtils.cp tmp_png_path, cover_path
    FileUtils.rm get_temp_path_for "#{filename}.svg"
    FileUtils.rm tmp_png_path
  end

  def create_cover(talk)
    arg_list = create_arg_list(talk)

    filename = "tmp_de_talk-#{SecureRandom.uuid}"
    svg_tmp = get_temp_path_for "#{filename}.svg"
    png_tmp = get_temp_path_for "#{filename}.png"

    FileUtils.cp SVG_TEMPLATE_APTH, svg_tmp

    output_png = get_temp_path_for png_tmp

    args = "sed -i'' -e #{arg_list.join(' -e ')} \"#{svg_tmp}\""

    if system(args)
      system("inkscape \"#{svg_tmp}\" -e \"#{output_png}\" &> /dev/null")
      sleep(2) #This sleep is mandatory to wait until inkscape processes the image
    end

    filename
  end

  def create_arg_list(talk)
    max_tag_caracters = 60

    [
      "\"s\#{{firstName}}\##{talk.first_name}\#\"",
      "\"s\#{{lastName}}\##{talk.last_name}\#\"",
      "\"s\#{{title}}\##{talk.title}\#\"",
      "\"s\#{{subtitle}}\##{talk.subtitle}\#\"",
      "\"s\#{{date}}\##{talk.date_str(:very_short)}\#\"",
      "\"s\#{{time}}\##{I18n.l(talk.time, format: :very_short)}\#\"",
      "\"s\#{{num}}\##{talk.number_formated}\#\"",
      "\"s\#{{keywords}}\##{talk.tag_list.to_s.truncate(max_tag_caracters)}\#\"",
      "\"s\#{{target}}\##{talk.target}\#\""
    ]
  end

  private

  def get_temp_path_for(filename)
    Rails.root.join('tmp', filename)
  end
end