require 'spec_helper'

describe 'rgbank', :type => :application do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      # Set Facts
      facts['ec2_metadata'] = nil
      facts['networking'] = {
        'domain' => "localdomain",
        'fqdn' => "localhost.localdomain",
        'hostname' => "localhost",
        'interfaces' => {
          'eth0' => {
            'ip' => "10.0.2.15",
          }
        }
      }
      facts['staging_http_get'] = 'curl'
      facts['root_home'] = '/root'



      context "on a single node setup" do
        let(:title) { 'getting-started' }
        let(:node) { 'test.puppet.com' }

        let :params do
          {
            :nodes => {
              ref('Node', node) => [
                ref('Rgbank::Load', 'getting-started'),
                ref('Rgbank::Web', "#{node}_getting-started"),
                ref('Rgbank::Db', 'getting-started'),
              ]
            }
          }
        end

        context 'with defaults for all parameters' do
          let(:pre_condition){'
            class { "::php": composer => false, }
            class { "::nginx": }
            include ::mysql::client
            class {"::mysql::bindings": php_enable => true, }
          '}
          it { should compile }
          it { should contain_rgbank(title).with(
                        'listen_port' => '8060',
                        'db_username' => 'test',
                        'db_password' => 'test',
                        'use_docker' => false,
                      ) }
          it { should contain_rgbank__db('getting-started').with(
                        'user'            => 'test',
                        'password'        => 'test',
                        'port'            => '3306',
                        'mock_sql_source' => 'https://raw.githubusercontent.com/puppetlabs/rgbank/master/rgbank.sql',
                      ) }
          it { should contain_rgbank__web("#{node}_getting-started").with(
                        'db_host'     => '10.0.2.15',
                        'db_name'     => 'rgbank-getting-started',
                        'db_user'     => 'test',
                        'db_password' => 'test',
                        'version'     => 'master',
                        'source'      => 'https://github.com/puppetlabs/rgbank',
                        'listen_port' => '8060',
                        'install_dir' =>  nil,
                        'image_tag'   => 'latest',
                      ) }
          it { should contain_rgbank__load('getting-started').with(
                        'port' => '80',
                      ) }

          it { should contain_file('/opt/rgbank-test.puppet.com_getting-started/git').with(
                        'ensure' => 'directory',
                      ) }

          it { should contain_file('/opt/rgbank-test.puppet.com_getting-started/wp-content/uploads').with(
                        'ensure' => 'directory',
                      ) }

          it { should contain_file('/var/lib/rgbank-getting-started').with(
                        'ensure' => 'directory',
                      ) }

          it { should contain_file('/opt/rgbank-test.puppet.com_getting-started/wp-content/themes/rgbank').with(
                        'ensure' => 'link',
                      ) }

          it { should contain_vcsrepo('/opt/rgbank-test.puppet.com_getting-started/git/rgbank') }

          it { should contain_firewall('000 accept rgbank getting-started load balanced connections') }
          it { should contain_firewall('000 accept rgbank web connections for test.puppet.com_getting-started') }
          it { should contain_mysql_user('test@localhost') }

          # Check for service resources
          it { should contain_database('getting-started') }
          it { should contain_http('getting-started') }
          it { should contain_http('rgbank-web-test.puppet.com_getting-started') }

          # Check for  defines (these are tested in their own modules so just validating they are present)
          it { should contain_nginx__resource__vhost('foo.example.com-test.puppet.com_getting-started') }
          it { should contain_nginx__resource__location('test.puppet.com_getting-started_root') }
          it { should contain_haproxy__balancermember('foo.example.com') }
          it { should contain_haproxy__listen('rgbank-getting-started') }
          it { should contain_mysql__db('rgbank-getting-started') }
          it { should contain_staging__file('rgbank-rgbank-getting-started.sql') }

          it { should contain_rgbank__web__base('test.puppet.com_getting-started').with(
            'version'     => 'master',
            'source'      => 'https://github.com/puppetlabs/rgbank',
            'listen_port' => '8060',
            'install_dir' => nil,
          ) }

          it { should contain_wordpress__instance__app('rgbank_test.puppet.com_getting-started').with(
            'db_host'           => '10.0.2.15',
            'db_name'           => 'rgbank-getting-started',
            'db_user'           => 'test',
            'db_password'       => 'test',
            'wp_config_content' => nil,
          )}
        end
      end
    end
  end
end

