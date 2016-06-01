module ServiceIntegrationHelper
  ERROR_MESSAGE = "When %s integration is actived, you need to provide on config/detalk.yml:\n%s\n".freeze

  def option_empty?(opt)
    opt.to_s.strip.blank?
  end

  def check_config_options!(service_name, options = [])
    return if option_empty? Rails.configuration.detalk[service_name]['active']

    invalid_options = options.collect { |option| check_option(service_name, option) }.compact

    Rails.logger.debug Rails.configuration.detalk[service_name]
    Rails.logger.debug invalid_options

    unless invalid_options.empty?
      msg = format ERROR_MESSAGE, service_name, invalid_options.join("\n")

      Rails.logger.error msg

      raise msg
    end
  end

  private

  def check_option(service_name, option)
    return option if option_empty? Rails.configuration.detalk[service_name][option]
  end
end