require 'rails_helper'

RSpec.describe "SuperAdmin::Schools", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/super_admin/schools/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/super_admin/schools/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/super_admin/schools/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/super_admin/schools/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/super_admin/schools/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/super_admin/schools/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/super_admin/schools/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
