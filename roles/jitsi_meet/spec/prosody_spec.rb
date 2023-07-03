require 'spec_helper'

describe file('/etc/prosody/conf.avail/localhost.cfg.lua') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its('mode') { should eq '644' }

  its('content') do
    should contain('VirtualHost "localhost"')
      .before('authentication = "anonymous"')
  end

  wanted_enabled_modules = %w(bosh pubsub ping)
  wanted_enabled_modules.each do |enabled_module|
    its('content') do
      should contain(enabled_module.to_s)
        .from(/^\s+modules_enabled = \{/)
        .to(/^\s+\}$/)
    end
  end
  its('content') do
    should contain('VirtualHost "auth.localhost"')
      .before('authentication = "internal_plain"')
  end

  wanted_config_line_pairs = {
    'VirtualHost "auth.localhost"' => 'authentication = "internal_plain"',
    'Component "conference.localhost" "muc"' =>
      'admins = { "focus@auth.localhost" }',
    'Component "jitsi-videobridge.localhost"' => 'component_secret = ',
    'Component "focus.localhost"' => 'component_secret = '
  }
  wanted_config_line_pairs.each do |line1, line2|
    regexp1 = /#{Regexp.quote(line1)}/
    regexp2 = /#{Regexp.quote(line2)}/
    regexp = /^#{regexp1}\n\s+#{regexp2}/m
    describe command('cat /etc/prosody/conf.avail/localhost.cfg.lua') do
      its('stdout') { should match(regexp) }
    end
  end

  describe command('luac -p /etc/prosody/conf.avail/localhost.cfg.lua') do
    its('exit_status') { should eq 0 }
  end

  describe file('/var/lib/prosody/auth%2elocalhost') do
    it { should be_directory }
    it { should be_owned_by 'prosody' }
    it { should be_grouped_into 'prosody' }
    its('mode') { should eq '750' }
  end

  describe file('/var/lib/prosody/auth%2elocalhost/accounts/focus.dat') do
    it { should be_file }
    it { should be_owned_by 'prosody' }
    it { should be_grouped_into 'prosody' }
    its('mode') { should eq '640' }
    regexp = /^\s+\["password"\] = "[\w@#]+";$/
    its('content') { should match(regexp) }
  end
end

# 5347 is the XMPP component port.
# Prosody listens on it, jicofo and jitsi-videobridge connect.
describe port(5347) do
  it { should be_listening }
  it { should be_listening.on('127.0.0.1') }
  it { should_not be_listening.on('0.0.0.0') }
end

describe command('sudo netstat -nlt') do
  its('stdout') { should match(/127\.0\.0\.1:5347/) }
  its('stdout') { should_not match(/0\.0\.0\.0:5347/) }
end
