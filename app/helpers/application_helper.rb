require 'rouge/plugins/redcarpet'

module ApplicationHelper
  def page_title
    base_title = "GRPM | Blog"
    if @title.nil?
      base_title
    else
      "#{@title} | #{base_title}"
    end
  end

  class HTML < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  def markdown(text)
    extensions = {
      no_intra_emphasis:   true,
      tables:              true,
      fenced_code_blocks:  true,
      space_after_headers: true,
      superscript:         true,
      footnotes:           true,
      strikethrough:       true,
      disabled_indented_code_blocks: true
    }

    options = {
      filter_html: true,
      prettify:    true
    }

    renderer = HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end
end
