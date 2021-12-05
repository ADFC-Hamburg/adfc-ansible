require 'spec_helper'

describe file('/etc/jitsi/jicofo/config') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its('mode') { should eq '644' }
  its('content') { should match(/^JICOFO_HOST=localhost$/) }
  its('content') { should match(/^JICOFO_PORT=5347$/) }
  # The regex for the "secret" may be off. Tests have failed before
  # when matching only '\w', due to a '@', so adding that.
  # Also have seen '#', so adding that. Would love a definitive
  # take on which characters are allowed here.
  its('content') { should match(/^JICOFO_SECRET=[\w@#]{8,}$/) }
  its('content') { should match(/^JICOFO_AUTH_PASSWORD=[\w@#]{8,}$/) }
  its('content') { should match(/^JICOFO_AUTH_USER=focus$/) }
end

describe file('/etc/jitsi/jicofo/logging.properties') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its('mode') { should eq '644' }
  its('content') { should match(/^\.level=INFO$/) }
end

describe service('jicofo') do
  it { should be_enabled }
  it { should be_running }
end

# Check that jicofo process is running as jicofo user
describe command('pgrep -u jicofo | wc -l') do
  its('stdout') { should eq "1\n" }
end
