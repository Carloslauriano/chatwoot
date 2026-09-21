class Api::V1::Accounts::LinkPreviewsController < Api::V1::Accounts::BaseController
  def create
    return render json: { error: 'url is required' }, status: :unprocessable_entity if params[:url].blank?

    render json: { title: LinkPreviewService.fetch(params[:url]) }
  end
end
