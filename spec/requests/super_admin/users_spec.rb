require 'rails_helper'

RSpec.describe "SuperAdmin::Users", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/super_admin/users/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/super_admin/users/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/super_admin/users/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/super_admin/users/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/super_admin/users/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
