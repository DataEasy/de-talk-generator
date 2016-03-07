module ApplicationHelper
  def active_if_current_page(path, exact_path = false)
    'active' if is_current_page_controller? path, exact_path
  end

  def is_current_page_controller?(path, exact_path)
    if exact_path
      controller.request.fullpath.eql? path
    else
      controller.request.fullpath.start_with? path
    end
  end
end
