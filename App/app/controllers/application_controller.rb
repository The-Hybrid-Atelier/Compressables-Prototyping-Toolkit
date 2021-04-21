class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def home
  	render layout: "iframe"
  end
  def app
  	@record = Record.new
    if params["scheme"]
      @records = Record.where(:label_scheme_id => params["scheme"]).order(:end_time => 'desc')
    else
      @records = Record.order(:end_time => 'desc')
    end
  	@feedbacks = Feedback.all
    @label_schemes = LabelScheme.all
    @data_models = DataModel.all
  	render layout: "mobile"
  end
  def app2
    @feedbacks = Feedback.all
    render layout: "mobile2"
  end
end
