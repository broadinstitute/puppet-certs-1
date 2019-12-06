require 'spec_helper'

describe 'kcerts::foreman_proxy' do
  let :facts do
    on_supported_os['redhat-7-x86_64']
  end

  describe 'with default parameters' do
    it { should compile.with_all_deps }
  end
end
