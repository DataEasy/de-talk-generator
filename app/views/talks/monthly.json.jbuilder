json.array!(@talks) do |talk|
  json.title "##{talk.number_formated} - #{talk.title}"
  json.start l(talk.date, locale: :en, format: :default).to_s
  json.cover_url url_to_image(talk.filename)
  json.url 'javascript:void(0);'
end