class TemplatesController < ApplicationController
  def create
    render layout: "application", inline: params.fetch(:template, <<~HTML)
      <form method="post">
        <p>Submit a POST request with a <tt>template</tt> value</p>

        <button name="template" value="Hello, world">Submit</button>
      </form>
    HTML
  end
end
