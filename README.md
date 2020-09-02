# OmniAuth V2.0 Windows Azure Active Directory Strategy

This gem provides a simple way to authenticate to Windows Azure Active Directory (WAAD) over OAuth2 using OmniAuth on specific integrations with Azure `v2.0` Endpoints.

##### Important: 
Again: Use this gem only if your single-sign-on endpoints has the Auth2 `v2.0` specified. If don't, take a look at: https://github.com/marknadig/omniauth-azure-oauth2.
#### Comments
One of the unique challenges of WAAD OAuth is that WAAD is multi tenant. Any given tenant can have multiple active
directories. The CLIENT-ID, REPLY-URL and keys will be unique to the tenant/AD/application combination. This gem simply
provides hooks for determining those unique values for each call.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-azure-oauth2-v2'
```

## Usage

First, you will need to add your site as an application in WAAD.:
[Adding, Updating, and Removing an Application](https://docs.microsoft.com/en-us/azure/active-directory/develop/)

Summary:
Your provider should pass some infos to you. Name, sign-on url, logo are not important.  You will need the CLIENT-ID from the application configuration and your provider will need to generate an Client Secret.  REPLY URL is the oauth redirect uri which will be the omniauth callback path https://example.com/users/auth/azure_oauth2/callback. The APP ID UI just needs to be unique to that tenant and identify your site and isn't needed to configure the gem.
Permissions need Delegated Permissions to at least have "Enable sign-on and read user's profiles".
If you want to change the basic sign-on url, specify the attribute base_azure_url when build the provider.
Note: Seems like the terminology is still fluid, so follow the MS guidance (buwahaha) to set this up.

The TenantInfo information can be a hash or class. It must provide client_id and client_secret.
Optionally a domain_hint and tenant_id. For a simple single-tenant app, this could be:
( Add this to the ominiauth initializer)
```ruby
use OmniAuth::Builder do
  provider :azure_oauth2_v2,
    {
      client_id: ENV['AZURE_CLIENT_ID'],
      client_secret: ENV['AZURE_CLIENT_SECRET'],
      tenant_id: ENV['AZURE_TENANT_ID']
    }
end
```

Next step is create the endpoint in your application that matches to the callback URL and then performs whatever steps are necessary for your application (If you're using devise, this example will work too). Add this line in your routes.rb file:
```ruby
match '/auth/:provider/callback' => 'sessions#create', via: [:get, :post]
````

if you're using devise, before this you must add:
```
devise_for :users
```

In some cases for security reasons the provider give acess to specific routes. In this cases, you will need to change your `redirect_uri`:
```ruby 
use OmniAuth::Builder do
  provider :azure_oauth2_v2,
    {
      client_id: ENV['AZURE_CLIENT_ID'],
      client_secret: ENV['AZURE_CLIENT_SECRET'],
      tenant_id: ENV['AZURE_TENANT_ID'],
      redirect_uri: 'http://redirect_path'
    }
end
```
and add on your routes:
```ruby 
post 'redirect_path': 'sessions#create'
```

After solve the route issues, add `SessionsController` with this code (don't forget to `include AzureAuthRequestHelper and before_action :user_info`)
The variable called by `@user_info` will have the response of Azure.

If `you're not using Devise`:
```ruby
class SessionsController < ApplicationController
  include AzureAuthRequestHelper
  before_action :user_info, only: [:create]
  def create
    if @user_info.first == :success
      @user = User.find_or_create_by(email: @user_info.second['email'].downcase)
      self.current_user = @user
    end
  end
end
```
if `you're using Devise (and needs to sign_in)`, copy this:
```ruby
class SessionsController < ApplicationController
  include AzureAuthRequestHelper
  before_action :user_info, only: [:create]
  def create
    if @user_info.first == :success
      @user = User.find_or_create_by(email: @user_info.second['email'].downcase)
      sign_in @user
    end
  end
end
```

For multi-tenant apps where you don't know the tenant_id in advance, simply leave out the tenant_id to use the 
[common endpoint](http://msdn.microsoft.com/en-us/library/azure/dn645542.aspx).

```ruby
use OmniAuth::Builder do
  provider :azure_oauth2_v2,
    {
      client_id: ENV['AZURE_CLIENT_ID'],
      client_secret: ENV['AZURE_CLIENT_SECRET']
    }
end
```

For dynamic tenant assignment, pass a class that supports those same attributes and accepts the strategy as a parameter

```ruby
class YouTenantProvider
  def initialize(strategy)
    @strategy = strategy
  end

  def client_id
    tenant.azure_client_id
  end

  def client_secret
    tenant.azure_client_secret
  end

  def tenant_id
    tenant.azure_tanant_id
  end

  def domain_hint
    tenant.azure_domain_hint
  end

  private

  def tenant
    # whatever strategy you want to figure out the right tenant from params/session
    @tenant ||= Customer.find(@strategy.session[:customer_id])
  end
end

use OmniAuth::Builder do
  provider :azure_oauth2_v2, YourTenantProvider
end
```

The base_azure_url can be overridden in the provider configuration for different locales; e.g. `base_azure_url: "https://login.microsoftonline.de"`


## Auth Hash Schema
Hash Schema can be different for differrent scenarios.
The following information is provided back to you for the provider (this will set in @user_info):
#### Success case
```ruby
{
  :sucess,
  {
    name: 'some one',
    first_name: 'some',
    last_name: 'one',
    email: 'someone@example.com'
  }
}
````
#### Error case
```ruby
{
  :error,
  {
    ErrorHash
  }
}
```
## Notes

When you make a request to WAAD you must specify a resource. The gem currently assumes this is the AD identified as '00000002-0000-0000-c000-000000000000'.
This can be passed in as part of the config. It currently isn't designed to be dynamic.

```ruby
use OmniAuth::Builder do
  provider :azure_oauth2_v2, TenantInfo, resource: 'myresource'
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes, add tests, run tests (`rake`)
4. Commit your changes and tests  (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request