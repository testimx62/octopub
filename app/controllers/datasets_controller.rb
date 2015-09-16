class DatasetsController < ApplicationController

  before_filter :clear_files, only: [:create, :update]
  before_filter :set_licenses, only: [:create, :new, :edit]
  before_filter(only: :index) { alternate_formats [:json, :feed] }
  before_filter :check_signed_in?, only: [:edit, :dashboard]

  def index
    @datasets = Dataset.all
  end

  def dashboard
    current_user.refresh_datasets if params[:refresh]
    @datasets = current_user.datasets
  end

  def new
    @dataset = Dataset.new
  end

  def create
    @dataset = current_user.datasets.new(dataset_params)
    if params["files"].count == 0
      flash[:notice] = "You must specify at least one dataset"
      render "new"
    else
      @dataset.save
      @dataset.add_files(params["files"])
      redirect_to datasets_path, :notice => "Dataset created sucessfully"
    end
  end

  def edit
    @dataset = current_user.datasets.where(id: params["id"]).first
    render_404 and return if @dataset.nil?
  end

  def update
  end

  private

  def clear_files
    params["files"].delete_if { |f| f["file"].nil? }
  end

  def set_licenses
    @licenses = [
                  "cc-by",
                  "cc-by-sa",
                  "cc0",
                  "OGL-UK-3.0",
                  "odc-by",
                  "odc-pddl"
                ].map do |id|
                  license = Odlifier::License.define(id)
                  [license.title, license.id]
                end
  end

  def dataset_params
    params.require(:dataset).permit(:name, :description, :publisher_name, :publisher_url, :license, :frequency)
  end

  def check_signed_in?
    render_404 if current_user.nil?
  end

end
