require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Add dataset page", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:schema_file) { get_fixture_file('schemas/good-schema.json') }

  before(:each) do
    allow_any_instance_of(DatasetsController).to receive(:current_user) { @user }
    Sidekiq::Testing.inline!
    visit root_path
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  context "logged in visitor has schemas and" do

    before(:each) do
      good_schema_url = url_with_stubbed_get_for_fixture_file('schemas/good-schema.json')
      create(:dataset_file_schema, url_in_repo: good_schema_url, name: 'good schema', description: 'good schema description', user: @user)
      click_link "Create a new data collection"
      expect(page).to have_content "Collection name"
    end

    it "can access add dataset page see they have the form options for a schema" do
      within 'form' do
        expect(page).to have_content "good schema"
        expect(page).to have_content "Save and add another file"
        expect(page).to have_content "No schema required"
      end
    end

  end

  context "logged in visitors has no schemas" do
    it "and can complete a simple dataset form without adding a schema" do

      repo = double(GitData)
      expect(repo).to receive(:html_url) { 'https://example.org' }
      expect(repo).to receive(:name) { 'examplename'}
      expect(repo).to receive(:full_name) { 'examplename' }
      expect(RepoService).to receive(:create_repo) { repo }
      expect(RepoService).to receive(:fetch_repo).at_least(:once) { repo }
      expect(RepoService).to receive(:prepare_repo).at_least(:once)
      click_link "Create a new data collection"

      allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(data_file))

      expect_any_instance_of(JekyllService).to receive(:create_data_files) { nil }
      expect_any_instance_of(JekyllService).to receive(:push_to_github) { nil }
      expect_any_instance_of(Dataset).to receive(:publish_public_views) { nil }

      common_name = 'Fri1437'

      before_datasets = Dataset.count
      expect(page).to have_selector(:link_or_button, "Submit")
      within 'form' do
        complete_form(page, common_name, data_file)
      end

      click_on 'Submit'

      expect(page).to have_content "Your data collection has been queued for creation and will be available as a pre-published collection on your dashboard shortly."
      expect(Dataset.count).to be before_datasets + 1
      expect(Dataset.last.name).to eq "#{common_name}-name"
      expect(Dataset.last.owner).to eq @user.github_username
    end
	end

  def complete_form(page, common_name, data_file, owner = nil, licence = nil)

    dataset_name = "#{common_name}-name"
    fill_in 'dataset[name]', with: dataset_name
    fill_in 'dataset[description]', with: "#{common_name}-description"
		click_on 'Next: Add a licence'
		click_on 'Next: Add your file(s)'
    fill_in 'files[][title]', with: "#{common_name}-file-name"
    fill_in 'files[][description]', with: "#{common_name}-file-description"
    attach_file("[files[][file]]", data_file)
    expect(page).to have_selector("input[value='#{dataset_name}']")

  end
end
