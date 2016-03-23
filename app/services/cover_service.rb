require 'fileutils'

class CoverService

  def create_cover(talk)
    arg_list = create_arg_list(talk)

    svg_source = Rails.root.join('app', 'assets', 'images', 'Template_DE_Talks.svg')

    filename = "tmp_de_talk-#{SecureRandom.uuid}"
    svg_tmp = Rails.root.join('tmp', "#{filename}.svg")
    png_tmp = Rails.root.join('tmp', "#{filename}.png")

    FileUtils.cp svg_source, svg_tmp

    output_png = Rails.root.join('tmp', png_tmp)

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
end