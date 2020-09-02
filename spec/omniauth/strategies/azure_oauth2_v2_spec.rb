require 'spec_helper'
require 'omniauth-azure-oauth2-v2'

module OmniAuth
  module Strategies
    module JWT; end
  end
end

describe OmniAuth::Strategies::AzureOauth2V2 do
  let(:request) { double('Request', :params => {}, :cookies => {}, :env => {}) }
  let(:app) {
    lambda do
      [200, {}, ["Hello."]]
    end
  }

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe 'static configuration' do
    let(:options) { @options || {} }
    subject do
      OmniAuth::Strategies::AzureOauth2V2.new(app, {client_id: 'id', client_secret: 'secret', tenant_id: 'tenant'}.merge(options))
    end

    describe '#client' do
      it 'has correct authorize url' do
        allow(subject).to receive(:request) { request }
        expect(subject.client.options[:authorize_url]).to eql('https://login.microsoftonline.com/tenant/oauth2/v2.0/authorize')
      end

      it 'has correct authorize params' do
        allow(subject).to receive(:request) { request }
        subject.client
        expect(subject.authorize_params[:domain_hint]).to be_nil
      end

      describe "overrides" do
        it 'should override domain_hint' do
          @options = {domain_hint: 'hint'}
          allow(subject).to receive(:request) { request }
          subject.client
          expect(subject.authorize_params[:domain_hint]).to eql('hint')
        end
      end
    end

  end

  describe 'static configuration - german' do
    let(:options) { @options || {} }
    subject do
      OmniAuth::Strategies::AzureOauth2V2.new(app, {client_id: 'id', client_secret: 'secret', tenant_id: 'tenant', base_azure_url: 'https://login.microsoftonline.de'}.merge(options))
    end

    describe '#client' do
      it 'has correct authorize url' do
        allow(subject).to receive(:request) { request }
        expect(subject.client.options[:authorize_url]).to eql('https://login.microsoftonline.de/tenant/oauth2/v2.0/authorize')
      end

      it 'has correct authorize params' do
        allow(subject).to receive(:request) { request }
        subject.client
        expect(subject.authorize_params[:domain_hint]).to be_nil
      end

      describe "overrides" do
        it 'should override domain_hint' do
          @options = {domain_hint: 'hint'}
          allow(subject).to receive(:request) { request }
          subject.client
          expect(subject.authorize_params[:domain_hint]).to eql('hint')
        end
      end
    end
  end

  describe 'static common configuration' do
    let(:options) { @options || {} }
    subject do
      OmniAuth::Strategies::AzureOauth2V2.new(app, {client_id: 'id', client_secret: 'secret'}.merge(options))
    end

    before do
      allow(subject).to receive(:request) { request }
    end

    describe '#client' do
      it 'has correct authorize url' do
        expect(subject.client.options[:authorize_url]).to eql('https://login.microsoftonline.com/common/oauth2/v2.0/authorize')
      end
    end
  end

  describe 'dynamic configuration' do
    let(:provider_klass) {
      Class.new {
        def initialize(strategy)
        end

        def client_id
          'id'
        end

        def client_secret
          'secret'
        end

        def tenant_id
          'tenant'
        end

        def authorize_params
          { custom_option: 'value' }
        end
      }
    }

    subject do
      OmniAuth::Strategies::AzureOauth2V2.new(app, provider_klass)
    end

    before do
      allow(subject).to receive(:request) { request }
    end

    describe '#client' do
      it 'has correct authorize url' do
        expect(subject.client.options[:authorize_url]).to eql('https://login.microsoftonline.com/tenant/oauth2/v2.0/authorize')
      end

      it 'has correct authorize params' do
        subject.client
        expect(subject.authorize_params[:domain_hint]).to be_nil
        expect(subject.authorize_params[:custom_option]).to eql('value')
      end
    end

  end

  describe 'dynamic configuration - german' do
    let(:provider_klass) {
      Class.new {
        def initialize(strategy)
        end

        def client_id
          'id'
        end

        def client_secret
          'secret'
        end

        def tenant_id
          'tenant'
        end

        def base_azure_url
          'https://login.microsoftonline.de'
        end
      }
    }

    subject do
      OmniAuth::Strategies::AzureOauth2V2.new(app, provider_klass)
    end

    before do
      allow(subject).to receive(:request) { request }
    end

    describe '#client' do
      it 'has correct authorize url' do
        expect(subject.client.options[:authorize_url]).to eql('https://login.microsoftonline.de/tenant/oauth2/v2.0/authorize')
      end

      it 'has correct authorize params' do
        subject.client
        expect(subject.authorize_params[:domain_hint]).to be_nil
      end
    end
  end

  describe 'dynamic common configuration' do
    let(:provider_klass) {
      Class.new {
        def initialize(strategy)
        end

        def client_id
          'id'
        end

        def client_secret
          'secret'
        end
      }
    }

    subject do
      OmniAuth::Strategies::AzureOauth2V2.new(app, provider_klass)
    end

    before do
      allow(subject).to receive(:request) { request }
    end

    describe '#client' do
      it 'has correct authorize url' do
        expect(subject.client.options[:authorize_url]).to eql('https://login.microsoftonline.com/common/oauth2/v2.0/authorize')
      end
    end
  end

  describe "raw_info" do
    subject do
      OmniAuth::Strategies::AzureOauth2V2.new(app, {client_id: 'id', client_secret: 'secret'})
    end

    let(:token) do
      JWT.encode({"some" => "payload"}, "secret")
    end

    let(:access_token) do
      double(:token => token)
    end

    before do
      allow(subject).to receive(:access_token) { access_token }
      allow(subject).to receive(:request) { request }
    end

    it "does not clash if JWT strategy is used" do
      expect do
        subject.info
      end.to_not raise_error
    end
  end

  describe 'token_params' do
    let(:strategy) { OmniAuth::Strategies::AzureOauth2V2.new(app, client_id: 'id', client_secret: 'secret') }
    let(:request)  { double('Request', env: env) }
    let(:env)      { {} }

    subject { strategy.token_params }

    before { allow(strategy).to receive(:request).and_return request }

    it { is_expected.to be_a OmniAuth::Strategy::Options }
  end
end
