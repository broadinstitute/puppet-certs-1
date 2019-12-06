require 'spec_helper'

describe 'kcerts' do

 context 'on redhat' do
    let :facts do
      on_supported_os['redhat-7-x86_64']
    end

    it { should contain_class('kcerts::install') }
    it { should contain_class('kcerts::config') }
  end

end
