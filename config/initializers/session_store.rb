# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_crossval_session',
  :secret      => 'b763ae0d72229868e61e4eabdacdae5923e751edd098992f806bd175d217770507e1bcab12f482a6e7348ad5e7e736d90c45251d9399582ca5dc2e729f6d6c04'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
