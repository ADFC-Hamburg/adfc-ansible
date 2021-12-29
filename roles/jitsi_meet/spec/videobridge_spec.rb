require 'spec_helper'

# This is the port which jvb will use to connect to prosody
jvb_service_port = 5347

describe file('/etc/jitsi/videobridge/config') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its('mode') { should eq '644' }
  its('content') { should match(/^JVB_HOSTNAME=localhost$/) }
  its('content') { should match(/^JVB_HOST=$/) }
  its('content') { should match(/^JVB_PORT=#{jvb_service_port}$/) }
  # It may be necessary to expand the regex for matching secrets.
  # See the jicofo tests for comparison.
  its('content') { should match(/^JVB_SECRET=\w{8,}$/) }
end

describe file('/etc/jitsi/videobridge/logging.properties') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its('mode') { should eq '644' }
  its('content') { should match(/^\.level=INFO$/) }
end

describe service('jitsi-videobridge') do
  it { should be_enabled }
  it { should be_running }
end

# Check that jitsi-videobridge process is running as jvb user
describe command('pgrep -u jvb | wc -l') do
  its('stdout') { should eq "1\n" }
end
