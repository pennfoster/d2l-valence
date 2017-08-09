# D2l::Valence

This gem is aimed at providing  a Ruby client for Desire2Learn's Valence Learning Framework APIs primarily 
used for integration with D2L Brightspace

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'd2l-valence'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install d2l-valence

## Usage

The first step is to get an API Key generated by your D2L Brightspace Admin.  They will require you to provide a  
`Trusted URL`.  This is the URL in your application that processes the authorisation response from the D2L Brightspace 
Server.  If you do not have a hosted server for you application at the time of development then you can use the AP Test 
Tool provided by D2L as the `Trusted URL`: https://apitesttool.desire2learnvalence.com/index.php

Once generated the key will include an `Application ID` and `Application Key` which is used in the authentication request.


### Authentication URL
To start the process of authentication you will need to generate an Authentication URL.

```ruby
app_context = D2L::Valence::AppContext.new(
  brightspace_host: 'partners.brightspace.com',
  app_id: 'l3LcL9Lvpyg-ViYNbK',
  app_key: 'mz5HRx6ER6jLMqKRv6Fw',
  api_version: '1.15' # optional defaults to 1.0
)

auth_url = app_context.auth_url('https://apitesttool.desire2learnvalence.com/index.php')
```

Once you have generated your authentication URL you can do a redirect to it in your application if you have your 
application hosted.  If you application is not hosted as yet and you're using the D2L API Test Tool then just paste the
URL into your browser and the API Test Tool will appear.  From there you'll be able to get the `User ID` and `User Key` 
which will be used in all subsequent authenticated requests.

__NB:__ You will need to be authenticated on your instance of D2L Brightspace in order for the above function as expected.
The Valence API uses that account for all subsequent authenticated requests for authorisation so it's important that 
you are authenticated with the right account.

### Authenticated Requests  
The D2L Valence API requires that all requests are signed with authentication details.  This is based on your `App ID` 
and `App Key` along with the `User ID` and `User Key` that you harvest from the authentication response from your D2L 
Server.  
 
#### User context creation
In order to make requests against the D2L Valence API you will need to create a `D2L::Valence::UserContext` instance.  This 
will then be used for all of your subsequent requests against the various D2L Valence APIs.  Following is an example of 
the user context creation when processing the D2L Authentication response.

```ruby
app_context = D2L::Valence::AppContext.new(
  brightspace_host: 'partners.brightspace.com',
  app_id: 'l3LcL9Lvpyg-ViYNbK',
  app_key: 'mz5HRx6ER6jLMqKRv6Fw',
  api_version: '1.15' # optional defaults to 1.0
)
  
user_id = params['x_a'] # query parameters from the response
user_key = params['x_b']
  
user_context = D2L::Valence::UserContext.new(
  app_context: app_context,
  user_id: user_id,
  user_key: user_key
)

```

Please note if you're using a application framework that supports sessions (e.g. Rails, Sinatra, etc) then it's probably 
best store the `User ID` and `User Key` in the session to allow for multiple API requests.


#### Route Format
When creating your request you will need to specify a `route`.  The format of the `route` provided when doing a request 
allows you to specify parameters that are replaced based on the `route_params` hash that you provide in the request 
creation.  The only parameter that's pre-populated is the `version` which is based on the api_version you supply when 
creating your application context.  It can, however be overridden when you supply your `route_params`.  Following are 
some examples of `route` and `route_params`

```ruby

# NB: For the following example the api_version in the app_context has been set to 1.0

route = '/d2l/api/lp/:version/:orgUnitId/groupcategories/:groupCategoryId'
route_params = {orgUnitId: 1, groupCategoryId: 23} # => /d2l/api/lp/1.0/1/groupcategories/23

route = '/d2l/api/lp/:version/users/whoami'
route_params = {version: '1.15'} # => /d2l/api/lp/1.15/users/whoami

```

### Request Examples

#### GET Request example

[GET /d2l/api/lp/(version)/users/whoami](http://docs.valence.desire2learn.com/res/user.html#get--d2l-api-lp-(version)-users-whoami)

```ruby
response = D2L::Valence::Request.new(
  user_context: user_context,
  http_method: 'GET',
  route: '/d2l/api/lp/:version/users/whoami'
).execute

response.code # => :HTTP_200
response.to_hash # => will yield the following hash
{
  "Identifier" => "1",
  "FirstName" => "Jack",
  "LastName" => "User",
  "UniqueName" => "jack.user",
  "ProfileIdentifier" => "OqW9594ZXT"
}
```

#### POST Request example
[POST /d2l/api/le/(version)/lti/link/(orgUnitId)¶](http://docs.valence.desire2learn.com/res/lti.html#post--d2l-api-le-(version)-lti-link-(orgUnitId))

```ruby

response = D2L::Valence::Request.new(
  user_context: user_context,
  http_method: 'POST',
  route: '/d2l/api/le/:version/lti/link/:orgUnitId',
  route_params: { orgUnitId: 123 },
  query_params: {
    Title: 'LTI Link',
    Url: 'http://myapplication.com/tool/launch',
    Description: 'Link for external tool',
    Key: '2015141297208',
    PlainSecret: 'a30be7c3550149b7a7daac3065f0e5e5',
    IsVisible: false,
    SignMessage: true,
    SignWithTc: true,
    SendTcInfo: true,
    SendContextInfo: true,
    SendUserId: true,
    SendUserName: true,
    SendUserEmail: true,
    SendLinkTitle: true,
    SendLinkDescription: true,
    SendD2LUserName: true,
    SendD2LOrgDefinedId: true,
    SendD2LOrgRoleId: true,
    UseToolProviderSecuritySettings: true,
    CustomParameters: nil
  }
).execute

response.code # => :HTTP_200
response.to_hash # => full details of the created LTI Link with OrgUnitId and LtiLinkId included
```

#### PUT Request example
[PUT /d2l/api/le/(version)/lti/link/(ltiLinkId)](http://docs.valence.desire2learn.com/res/lti.html#put--d2l-api-le-(version)-lti-link-(ltiLinkId))

```ruby
response = D2L::Valence::Request.new(
  user_context: user_context,
  http_method: 'PUT',
  route: '/d2l/api/le/:version/lti/link/:ltiLinkId',
  route_params: { ltiLinkId: '123' },
  query_params: { Title: 'New LTI Link Title' }
).execute

response.code # => :HTTP_200
response.to_hash # => full details of the updated LTI Link with OrgUnitId and LtiLinkId included
```

#### DELETE Request example
[DELETE /d2l/api/le/(version)/lti/link/(ltiLinkId)](http://docs.valence.desire2learn.com/res/lti.html#delete--d2l-api-le-(version)-lti-link-(ltiLinkId))

```ruby
response = D2L::Valence::Request.new(
  user_context: user_context,
  http_method: 'DELETE',
  route: '/d2l/api/le/:version/lti/link/:ltiLinkId',
  route_params: { ltiLinkId: '123' }
).execute

response.code # => :HTTP_200
response.to_hash # => {}

```

#### Request failures  
Other than the normal HTTP response codes for failures there are a number of D2L Valence API specific response codes 
that will appear with the right conditions.

##### :INVALID_TIMESTAMP  
This response code identifies that there is enough of a difference between your local server time and the D2L Server 
time to be a problem.  For developers this is hard to have changed so we provided a mechanism where by the failure can 
be rectified at the application level.  In the design of the gem there is detection of time skew between the client and
server.  This is compensated for automatically.  Should your request get this failure then all you need do is execute 
your request a second time and the gem will take the skew into consideration when creating the necessary authentication 
tokens.  Following is an example of handling the response:

```ruby
request = D2L::Valence::Request.new(
  user_context: user_context,
  http_method: 'GET',
  route: '/d2l/api/lp/:version/users/whoami'
)

response = request.execute
response = request.execute if response.code == :INVALID_TIMESTAMP
response.code # => :HTTP_200

```

##### :INVALID_TOKEN  
This response code occurs, as it suggests when you have provided an invalid set of authentication tokens.  This could 
be a combination of incorrect App ID/Key and/or User ID/Key.   
 
## Contributing

1. Fork it ( https://github.com/michael-harrison/d2l-valence/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Testing notes  
Given the use of timestamps in the the URL it does mean that any tests that have recorded HTTP traffic via [VCR](https://github.com/vcr/vcr) 
need to use [Timecop](https://github.com/travisjeffery/timecop).  In some cases the calls will need to wrapped with a 
Timecop block:

```ruby
Timecop.freeze Time.at(1491780043) do
  # Your HTTP Calls
end
```

But for the majority of the tests it just a matter of adding a `before` and `after`:

```ruby
before { Timecop.freeze Time.at(1491547536) }
after { Timecop.return }
```

In order to do PRs with passing tests you'll need to use your own temporary App ID, App Key, User ID and User Key as I've
done with these tests.  For convenience the tests uses environment variables:
 
```ruby
let(:app_id) { ENV['D2L_API_ID'] }
let(:app_key) { ENV['D2L_API_KEY'] }
let(:user_id) { ENV['D2L_USER_ID'] }
let(:user_key) { ENV['D2L_USER_KEY'] }
```

It is a merry dance but the only reliable way to have real testing against a real API.
