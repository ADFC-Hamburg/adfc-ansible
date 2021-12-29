require 'spec_helper'

describe package('apt-transport-https') do
  it { should be_installed }
end

describe command('apt-cache policy') do
  jitsi_apt_repo_stable = <<APT_REPO_STABLE
 500 https://download.jitsi.org/ stable/ Packages
     release o=jitsi.org,a=stable,n=stable,l=Jitsi Debian packages repository,c=
     origin download.jitsi.org
APT_REPO_STABLE
  jitsi_apt_repo_unstable = <<APT_REPO_UNSTABLE
 500 https://download.jitsi.org/ unstable/ Packages
     release o=jitsi.org,a=unstable,n=unstable,l=Jitsi Debian packages repository,c=
     origin download.jitsi.org
APT_REPO_UNSTABLE
  if ENV['TARGET_HOST'].end_with?('unstable')
    its('stdout') { should include(jitsi_apt_repo_unstable) }
    its('stdout') { should_not include(jitsi_apt_repo_stable) }
  else
    its('stdout') { should include(jitsi_apt_repo_stable) }
    its('stdout') { should_not include(jitsi_apt_repo_unstable) }
  end
end

describe file('/etc/apt/sources.list.d/jitsi_meet.list') do
  it { should exist }
  its('mode') { should eq '644' }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end

describe command('apt-key finger') do
  jitsi_apt_key = <<APT_KEY
pub   4096R/2DC1389C 2016-06-23
      Key fingerprint = 66A9 CD05 95D6 AFA2 4729  0D3B EF8B 479E 2DC1 389C
uid                  Jitsi <dev@jitsi.org>
sub   4096R/88D3172B 2016-06-23
APT_KEY

  # TODO: Perhaps this key still refers to unstable repo?
  jitsi_apt_key_incorrect = <<APT_KEY_UNWANTED
pub   1024D/EB0AB654 2008-06-20
      Key fingerprint = 040F 5760 8F84 BAF1 BF84  4A62 C697 D823 EB0A B654
uid                  SIP Communicator (Debian package) <deb-pkg@sip-communicator.org>
sub   2048g/F6EFCE13 2008-06-20
APT_KEY_UNWANTED
  its('stdout') { should include(jitsi_apt_key) }
  its('stdout') { should_not include(jitsi_apt_key_incorrect) }
end
