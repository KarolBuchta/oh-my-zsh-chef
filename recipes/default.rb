#
# Cookbook Name:: oh_my_zsh
# Recipe:: default
#

unless platform?("mac_os_x")
  if node['oh_my_zsh']['users'].any?
    package "zsh"
    include_recipe "git"
  end
end

# for each listed user
node['oh_my_zsh']['users'].each do |user_hash|

  home_directory = `cat /etc/passwd | grep "^#{user_hash[:login]}:" | cut -d ":" -f6`.chop

  if platform?("mac_os_x")
    home_directory = `echo ~#{user_hash[:login]}`.chop
  end

  git "#{home_directory}/.oh-my-zsh" do
    repository node['oh_my_zsh'][:repository]
    user user_hash[:login]
    reference "master"
    action :sync
  end

  template "#{home_directory}/.zshrc" do
    source "zshrc.erb"
    owner user_hash[:login]
    mode "644"
    action :create_if_missing
    variables({
      :user => user_hash[:login],
      :theme => user_hash[:theme] || 'robbyrussell',
      :case_sensitive => user_hash[:case_sensitive] || false,
      :plugins => user_hash[:plugins] || %w(git)
    })
  end

  user user_hash[:login] do
    action :modify
    shell '/bin/zsh'
  end

  if platform?("debian", "ubuntu")
    execute "source /etc/profile to all zshrc" do
      command "echo 'source /etc/profile' >> /etc/zsh/zprofile"
      not_if "grep 'source /etc/profile' /etc/zsh/zprofile"
    end
  end

end
